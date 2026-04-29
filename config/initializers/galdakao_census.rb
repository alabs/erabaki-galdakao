# frozen_string_literal: true

# Registra el action authorizer de calles para el handler de autorización censal.
# Esto hace que cuando un componente tenga restricción por calle,
# Decidim use CensusActionAuthorizer para validar el acceso.

# INSTRUCCIONES:
# Busca en config/initializers/decidim.rb (o donde tengas el registro del handler)
# la línea donde registras census_authorization_handler y añade action_authorizer_name.
#
# Si usas Decidim::Verifications.register_workflow, el bloque queda así:
#
#   Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
#     workflow.action_authorizer_name = "CensusActionAuthorizer"
#   end
#
# Si usas config.authorization_handlers como array de hashes, queda así:
#
#   config.authorization_handlers = [
#     {
#       name: "census_authorization_handler",
#       action_authorizer_name: "CensusActionAuthorizer"
#     }
#   ]
#
#
## Se uso, Decidim::Verifications.register_workflow.

# Puedes dejar este archivo como initializer propio o fusionarlo con decidim.rb.

# Autoload de las clases de Galdakao en desarrollo
Rails.application.config.to_prepare do
  GaldakaoStreet
  GaldakaoWebservice
  CensusActionAuthorizer
end