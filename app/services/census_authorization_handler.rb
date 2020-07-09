# frozen_string_literal: true
# Checks the authorization against the census for Getxo.
require "digest/md5"

# This class performs a check against the official census database in order
# to verify the citizen's residence.
class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  include ActionView::Helpers::SanitizeHelper
  include Virtus::Multiparams

  attribute :document_number, String
  attribute :date_of_birth, Date

  validates :date_of_birth, presence: true
  validates :document_number, format: { with: /\A[a-zA-Z]?\d{7,8}[a-zA-Z]\z/ }, presence: true

  validate :document_number_valid

  # If you need to store any of the defined attributes in the authorization you
  # can do it here.
  #
  # You must return a Hash that will be serialized to the authorization when
  # it's created, and available though authorization.metadata
  def metadata
    super.merge(
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d")
    )
  end

  def unique_id
    Digest::MD5.hexdigest(
      "#{document_number&.upcase}-#{Rails.application.secrets.secret_key_base}"
    )
  end

  private

  def sanitized_date_of_birth
    @sanitized_date_of_birth ||= date_of_birth&.strftime("%Y%m%d")
  end

  def sanitized_document_number
    (/\d+/.match document_number)[0]
  end

  def sanitized_document_letter
    (/[a-zA-Z]\z/.match document_number)[0]&.upcase
  end
  
  def document_number_valid
    return nil if response.blank?

    errors.add(:document_number, I18n.t("census_authorization_handler.invalid_document")) unless response.xpath("//existe").text == "SI"
  end

  def response
    return nil if document_number.blank? ||
                  date_of_birth.blank?

    return @response if defined?(@response)

    response ||= Faraday.post Rails.application.secrets.census_url do |request|
      request.headers["Content-Type"] = "text/xml;charset=UTF-8'"
      request.headers["SOAPAction"] = %w{"http://webtests02.getxo.org/Validar"}
      request.body = request_body
    end

    @response ||= Nokogiri::XML(response.body).remove_namespaces!
  end


  def request_body
    @request_body ||= <<EOS
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Validar xmlns="http://webtests02.getxo.org/">
      <strDNI>#{sanitized_document_number}</strDNI>
      <strLetra>#{sanitized_document_letter}</strLetra>
      <strNacimiento>#{sanitized_date_of_birth}</strNacimiento>
    </Validar>
  </soap:Body>
</soap:Envelope>
EOS
  end
end