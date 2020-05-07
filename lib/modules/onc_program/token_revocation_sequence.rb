# frozen_string_literal: true

module Inferno
  module Sequence
    class TokenRevocationSequence < SequenceBase
      title 'Token Revocation'
      description 'Demonstrate the Health IT module is capable of revoking access granted to an application.'

      test_id_prefix 'TR'

      requires :bulk_client_id, :bulk_jwks_url_auth, :bulk_encryption_method, :bulk_token_endpoint, :bulk_scope
      defines :bulk_access_token

      test 'Test to be implemented by v1.0' do
        metadata do
          id '01'
          link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'
          description %(
              Test description
          )
        end
      end
    end
  end
end