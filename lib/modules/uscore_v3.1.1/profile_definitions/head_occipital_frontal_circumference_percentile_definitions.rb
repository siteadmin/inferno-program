# frozen_string_literal: true

module Inferno
  module USCore311ProfileDefinitions
    class USCore311HeadOccipitalFrontalCircumferencePercentileSequenceDefinitions
      MUST_SUPPORTS = {
        extensions: [],
        slices: [
          {
            name: 'Observation.category:VSCat',
            path: 'category',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'coding.code',
                  value: 'vital-signs'
                },
                {
                  path: 'coding.system',
                  value: 'http://terminology.hl7.org/CodeSystem/observation-category'
                }
              ]
            }
          },
          {
            name: 'Observation.value[x]:valueQuantity',
            path: 'value',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          }
        ],
        references: [
          {
            path: 'subject',
            resource_types: [
              'Patient'
            ]
          }
        ],
        elements: [
          {
            path: 'status'
          },
          {
            path: 'category'
          },
          {
            path: 'category.coding'
          },
          {
            path: 'category.coding.system',
            fixed_value: 'http://terminology.hl7.org/CodeSystem/observation-category'
          },
          {
            path: 'category.coding.code',
            fixed_value: 'vital-signs'
          },
          {
            path: 'code.coding.code',
            fixed_value: '8289-1'
          },
          {
            path: 'effectiveDateTime'
          },
          {
            path: 'effectivePeriod'
          },
          {
            path: 'effective'
          },
          {
            path: 'valueQuantity'
          },
          {
            path: 'value'
          },
          {
            path: 'value.value'
          },
          {
            path: 'value.unit'
          },
          {
            path: 'value.system',
            fixed_value: 'http://unitsofmeasure.org'
          },
          {
            path: 'value.code',
            fixed_value: '%'
          }
        ]
      }.freeze

      DELAYED_REFERENCES = [].freeze

      BINDINGS = [
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/observation-status',
          path: 'status'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'code'
        },
        {
          type: 'code',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/quantity-comparator',
          path: 'value.comparator'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'interpretation'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-vitalsignresult',
          path: 'component.code'
        },
        {
          type: 'Quantity',
          strength: 'required',
          system: 'http://hl7.org/fhir/ValueSet/ucum-vitals-common',
          path: 'component.value'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/data-absent-reason',
          path: 'component.dataAbsentReason'
        },
        {
          type: 'CodeableConcept',
          strength: 'extensible',
          system: 'http://hl7.org/fhir/ValueSet/observation-interpretation',
          path: 'component.interpretation'
        }
      ].freeze
    end
  end
end
