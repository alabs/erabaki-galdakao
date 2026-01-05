# frozen_string_literal: true

require "digest/md5"

# Checks the authorization against the census via SOAP.
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  attribute :document_number, String
  attribute :date_of_birth, Date

  validates :date_of_birth, presence: true
  validates :document_number,
            presence: true,
            format: { with: /\A[a-zA-Z]?\d{7,8}[a-zA-Z]\z/ }

  validate :document_number_valid

  # Accept multiparam dates coming from Rails date_select, e.g.
  # date_of_birth(1i)=YYYY, (2i)=MM, (3i)=DD
  def date_of_birth=(value)
    if value.is_a?(Hash)
      y = value["(1i)"] || value["1i"] || value[:'(1i)'] || value[:'1i'] || value[:year]  || value["year"]
      m = value["(2i)"] || value["2i"] || value[:'(2i)'] || value[:'2i'] || value[:month] || value["month"]
      d = value["(3i)"] || value["3i"] || value[:'(3i)'] || value[:'3i'] || value[:day]   || value["day"]

      parsed =
        if [y, m, d].all?(&:present?)
          begin
            Date.new(y.to_i, m.to_i, d.to_i)
          rescue ArgumentError
            nil
          end
        end

      return super(parsed)
    end

    super(value)
  end

  def metadata
    super.merge(
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d")
    )
  end

  def unique_id
    Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secrets.secret_key_base}")
  end

  private

  def sanitized_date_of_birth
    date_of_birth&.strftime("%Y%m%d")
  end

  def sanitized_document_number
    document_number.to_s[/\d+/]
  end

  def sanitized_document_letter
    document_number.to_s[/[a-zA-Z]\z/]&.upcase
  end

  def document_number_valid
    return if response.blank?

    exists = response.at_xpath("//existe")&.text
    return if exists == "SI"

    errors.add(:document_number, I18n.t("census_authorization_handler.invalid_document"))
  end

  def response
    return if document_number.blank? || date_of_birth.blank?
    return @response if defined?(@response)

    census_url = Rails.application.secrets.census_url
    return if census_url.blank?

    faraday_response = Faraday.post(census_url) do |request|
      request.headers["Content-Type"] = "text/xml; charset=UTF-8"
      request.headers["SOAPAction"] = "http://webtests02.getxo.org/Validar"
      request.body = request_body
    end

    @response = Nokogiri::XML(faraday_response.body).remove_namespaces!
  end

  def request_body
    <<~XML
      <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                     xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <Validar xmlns="http://webtests02.getxo.org/">
            <strDNI>#{sanitized_document_number}</strDNI>
            <strLetra>#{sanitized_document_letter}</strLetra>
            <strNacimiento>#{sanitized_date_of_birth}</strNacimiento>
          </Validar>
        </soap:Body>
      </soap:Envelope>
    XML
  end
end
