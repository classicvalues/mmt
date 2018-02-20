# UmmServiceKeywordPicker is used for a nested item picker
# populated with Service Keywords

# :nodoc:
class UmmServiceKeywordPicker < UmmScienceKeywordPicker
  KEYWORD_LEVELS = %w(
    ServiceCategory
    ServiceTopic
    ServiceTerm
    ServiceSpecificTerm
  ).freeze

  def keyword_type
    'service'
  end

  def render_preview
    capture do
      element_value.each do |keyword|
        concat(content_tag(:ul, class: 'arrow-tag-group-list') do
          KEYWORD_LEVELS.each do |level|
            unless keyword[level].blank?
              concat content_tag(:li, keyword[level], itemprop: 'keyword', class: 'arrow-tag-group-item')
            end
          end
        end)
      end
    end
  end

  def render_keyword_list(element, object)
    content_tag(:div, class: "selected-#{keyword_type}-keywords #{keyword_type}-keywords") do
      concat(content_tag(:ul) do
        Array.wrap(object).each_with_index do |keyword, index|
          concat(content_tag(:li) do
            concat keyword_string(keyword)

            remove_link = UmmRemoveLink.new(form_section_json: parsed_json, json_form: json_form, schema: schema, options: { name: keyword })
            concat remove_link.render_markup

            concat hidden_field_tag("#{keyify_property_name(element)}[#{index}][service_category]", keyword.fetch('ServiceCategory', ''))
            concat hidden_field_tag("#{keyify_property_name(element)}[#{index}][service_topic]", keyword.fetch('ServiceTopic', ''))
            concat hidden_field_tag("#{keyify_property_name(element)}[#{index}][service_term]", keyword.fetch('ServiceTerm', ''))
            concat hidden_field_tag("#{keyify_property_name(element)}[#{index}][service_specific_term]", keyword.fetch('ServiceSpecificTerm', ''))
          end)
        end
      end)

      # Element that holds all attributes for a hidden input that is used for form validation within it's data attributes
      concat content_tag(:span, nil, element_properties(schema_fragment).merge(id: "empty_#{idify_property_name(element)}", data: { id: idify_property_name(element), name: keyify_property_name(element) }))
    end
  end
end
