# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore311ProcedureSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore311ProcedureSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.1')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Procedure search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @procedure = FHIR.from_contents(load_fixture(:us_core_procedure))
      @procedure_ary = { @sequence.patient_ids.first => @procedure }
      @sequence.instance_variable_set(:'@procedure', @procedure)
      @sequence.instance_variable_set(:'@procedure_ary', @procedure_ary)

      @query = {
        'patient': @sequence.patient_ids.first
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        []
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Procedure.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Procedure.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'fails if the bundle contains a resource which is not the searched for resource nor an OperationOutcome' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle([FHIR::Procedure.new, FHIR::Specimen.new, FHIR::PaymentNotice.new]).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'All resources returned must be of the type Procedure or OperationOutcome, but includes Specimen, PaymentNotice', exception.message
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      operation_outcome = FHIR.from_contents(load_fixture(:operationoutcome_example))

      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@procedure_ary.values.flatten.append(operation_outcome)).to_json)

      reference_with_type_params = @query.merge('patient': 'Patient/' + @query[:patient])
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: reference_with_type_params, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@procedure_ary.values.flatten.append(operation_outcome)).to_json)

      stub_request(:post, "#{@base_url}/Procedure/_search")
        .with(body: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@procedure_ary.values.flatten.append(operation_outcome)).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Procedure.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@procedure]).to_json)

        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('patient': 'Patient/' + @query[:patient], 'status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@procedure]).to_json)
        stub_request(:post, "#{@base_url}/Procedure/_search")
          .with(headers: @auth_header, body: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first))
          .to_return(status: 200, body: wrap_resources_in_bundle([@procedure]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Procedure search by patient+date test' do
    before do
      @test = @sequence_class[:search_by_patient_date]
      @sequence = @sequence_class.new(@instance, @client)
      @procedure = FHIR.from_contents(load_fixture(:us_core_procedure))
      @procedure_ary = { @sequence.patient_ids.first => @procedure }
      @sequence.instance_variable_set(:'@procedure', @procedure)
      @sequence.instance_variable_set(:'@procedure_ary', @procedure_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'performed'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Procedure resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@procedure_ary', @sequence.patient_ids.first => FHIR::Procedure.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Procedure.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Procedure.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Procedure.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
      end
    end
  end

  describe 'Procedure search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @procedure = FHIR.from_contents(load_fixture(:us_core_procedure))
      @procedure_ary = { @sequence.patient_ids.first => @procedure }
      @sequence.instance_variable_set(:'@procedure', @procedure)
      @sequence.instance_variable_set(:'@procedure_ary', @procedure_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'status'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Procedure resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@procedure_ary', @sequence.patient_ids.first => FHIR::Procedure.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Procedure.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Procedure.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      operation_outcome = FHIR.from_contents(load_fixture(:operationoutcome_example))

      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@procedure_ary.values.flatten.append(operation_outcome)).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Procedure search by patient+code+date test' do
    before do
      @test = @sequence_class[:search_by_patient_code_date]
      @sequence = @sequence_class.new(@instance, @client)
      @procedure = FHIR.from_contents(load_fixture(:us_core_procedure))
      @procedure_ary = { @sequence.patient_ids.first => @procedure }
      @sequence.instance_variable_set(:'@procedure', @procedure)
      @sequence.instance_variable_set(:'@procedure_ary', @procedure_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'code')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'performed'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'code'), true),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@procedure_ary[@sequence.patient_ids.first], 'performed'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'code']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Procedure resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@procedure_ary', @sequence.patient_ids.first => FHIR::Procedure.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Procedure.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Procedure")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Procedure.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Procedure")
          .with(query: @query.merge('status': ['preparation,in-progress,not-done,on-hold,stopped,completed,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Procedure.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Procedure', exception.message
      end
    end
  end

  describe 'Procedure read test' do
    before do
      @procedure_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@procedure', FHIR::Procedure.new(id: @procedure_id))
    end

    it 'skips if the Procedure read interaction is not supported' do
      Inferno::ServerCapabilities.delete_all
      Inferno::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.as_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Procedure read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Procedure has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Procedure resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Procedure' do
      Inferno::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Procedure.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      procedure = FHIR::Procedure.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: procedure.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@procedure_id}", exception.message
    end

    it 'succeeds when a Procedure resource is read successfully' do
      procedure = FHIR::Procedure.new(
        id: @procedure_id
      )
      Inferno::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: procedure.to_json)

      @sequence.run_test(@test)
    end
  end
end
