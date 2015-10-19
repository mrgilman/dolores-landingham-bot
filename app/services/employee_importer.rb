require "slack-ruby-client"

class EmployeeImporter
  def initialize
    configure_slack
  end

  def import(dry_run = false)
    import_results = {created: 0, skipped: 0, dry_run: false}
    slack_user_importer = SlackUserImporter.new("", client)
    total_employees = slack_user_importer.slack_usernames.count

    slack_user_importer.slack_usernames.each_with_index do |slack_username, index|
      if !dry_run
        success = import_employee(slack_username)
      else
        success = dry_import_employee(slack_username)
        import_results[:dry_run] = true
      end

      if success
        Rails.logger.info "#{index + 1}/#{total_employees}: Created #{slack_username}#{" (dry run)" if dry_run}".green
        import_results[:created] += 1
      else
        Rails.logger.info "#{index + 1}/#{total_employees}: Skipped #{slack_username}#{" (dry run)" if dry_run}".yellow
        import_results[:skipped] += 1
      end
    end

    import_results
  end

  private

  def client
    @client ||= Slack::Web::Client.new
  end

  def configure_slack
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
  end

  def dry_import_employee(slack_username)
    Employee.where(slack_username: slack_username).size == 0
  end

  def import_employee(slack_username)
    # TODO:  Once we can hook up the Team API, we'll want to grab the start
    # TODO:  date of an employee from there instead of defaulting to the
    # TODO:  current date and time.

    # TODO:  We'll also want to verify that the Slack user is an actual person
    # TODO:  Against the Team API - Slack alone cannot tell us if they are real
    # TODO:  or not.

    employee = Employee.new(slack_username: slack_username, started_on: Time.now)
    employee.save
  end
end
