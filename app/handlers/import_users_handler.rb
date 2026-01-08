# frozen_string_literal: true

require 'csv'
require 'stringio'

require_relative '../../lib/pachca_handlers/handlers/base_handler'

class ImportUsersHandler < PachcaHandlers::Handlers::BaseHandler
  title 'Import Users (CSV)'
  command 'import_users'

  step :upload do
    intro 'Upload a CSV file with headers: name,email'

    field :csv do
      name 'CSV file'
      description 'Attach a .csv file'
      input :file

      callback do |ctx|
        file = ctx[:value]
        preview = csv_preview(file[:url])

        ctx.set_field(:csv, file.merge(preview: preview))
        "Got `#{file[:name] || 'file'}`. Preview:\n#{preview}"
      end
    end
  end

  step :confirm do
    intro 'Continue with the import?'

    field :confirm do
      name 'Confirm'
      options %w[Import Cancel]
    end
  end

  step :import do
    callback do |ctx|
      return PachcaHandlers::Result.success('Cancelled') if ctx.get_field_value(:confirm, :confirm) == 'Cancel'

      file = ctx.get_field_value(:upload, :csv)
      url = file[:url]

      rows = parse_users_csv(url)
      normalized_csv = CSV.generate do |csv|
        csv << %w[name email]
        rows.each { |r| csv << [r[:name], r[:email]] }
      end

      uploaded = ctx.upload_file(
        StringIO.new(normalized_csv),
        filename: 'imported_users.csv',
        content_type: 'text/csv'
      )

      ctx.send_message("Parsed #{rows.size} users. Attached normalized CSV.", files: [uploaded])
      nil
    end
  end

  private

  def csv_preview(url)
    rows = parse_users_csv(url).first(3)
    return '(no rows found)' if rows.empty?

    rows.map { |r| "#{r[:name]}, #{r[:email]}" }.join("\n")
  end

  def parse_users_csv(url)
    body = PachcaHandlers::Integrations::BaseClient.get(url).body.to_s
    table = CSV.parse(body, headers: true)

    table.filter_map do |row|
      name = row['name'] || row['Name']
      email = row['email'] || row['Email']
      next if name.to_s.strip.empty? || email.to_s.strip.empty?

      { name: name.to_s.strip, email: email.to_s.strip }
    end
  end
end
