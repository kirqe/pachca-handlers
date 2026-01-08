# frozen_string_literal: true

# Expected CSV format:
#   name,email
#   Alice Example,alice@example.com
#   Bob Example,bob@example.com
#
# Notes:
# - The file must include headers (exactly `name,email`) and at least one row.
# - This handler downloads the attachment and parses it locally (max size is enforced by ctx.download_file).

require 'csv'
require 'stringio'

require_relative '../../lib/pachca_handlers/handlers/base_handler'

class ImportUsersHandler < PachcaHandlers::Handlers::BaseHandler
  class CSVFormatError < StandardError; end

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
        preview = csv_preview(ctx, file)

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
      return PachcaHandlers::Result.success('Cancelled') if cancelled?(ctx)

      rows = parsed_rows(ctx)
      normalized_csv = build_normalized_csv(rows)
      uploaded = upload_normalized_csv(ctx, normalized_csv)

      ctx.send_message(import_summary(rows), files: [uploaded])
      nil
    rescue CSVFormatError => e
      PachcaHandlers::Result.error(e.message)
    end
  end

  private

  def cancelled?(ctx)
    ctx.get_field_value(:confirm, :confirm) == 'Cancel'
  end

  def parsed_rows(ctx)
    file = ctx.get_field_value(:upload, :csv)
    rows = parse_users_csv(ctx, file)
    raise CSVFormatError, 'CSV must include at least one user row' if rows.empty?

    rows
  end

  def build_normalized_csv(rows)
    CSV.generate do |csv|
      csv << %w[name email]
      rows.each { |r| csv << [r[:name], r[:email]] }
    end
  end

  def upload_normalized_csv(ctx, csv_string)
    ctx.upload_file(
      StringIO.new(csv_string),
      filename: 'imported_users.csv',
      content_type: 'text/csv'
    )
  end

  def import_summary(rows)
    "Parsed #{rows.size} users. Attached normalized CSV."
  end

  def csv_preview(ctx, file)
    rows = parse_users_csv(ctx, file).first(3)
    return '(no rows found)' if rows.empty?

    rows.map { |r| "#{r[:name]}, #{r[:email]}" }.join("\n")
  end

  def parse_users_csv(ctx, file_or_url)
    tempfile = ctx.download_file(file_or_url)
    body = tempfile.read.to_s
    table = CSV.parse(body, headers: true)
    validate_headers!(table)

    table.filter_map do |row|
      name = row['name']
      email = row['email']
      next if name.to_s.strip.empty? || email.to_s.strip.empty?

      { name: name.to_s.strip, email: email.to_s.strip }
    end
  ensure
    tempfile&.close!
  end

  def validate_headers!(table)
    headers = (table.headers || []).map(&:to_s)
    return if headers.include?('name') && headers.include?('email')

    raise CSVFormatError, 'CSV headers must include: name,email'
  end
end
