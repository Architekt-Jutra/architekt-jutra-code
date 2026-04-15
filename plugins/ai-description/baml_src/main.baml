class ProductDescription {
  recommendation string
  targetCustomer string
  pros string[]
  cons string[]
}

function GenerateProductDescription(
  productName: string,
  productDescription: string,
  customInformation: string?
) -> ProductDescription {
  client LlmProvider
  prompt #"
    You are a product analyst. Analyze the following product and provide a structured description.

    Product Name: {{ productName }}
    Product Description: {{ productDescription }}
    {% if customInformation %}
    Additional Information: {{ customInformation }}
    {% endif %}

    Provide:
    1. A recommendation summary for potential buyers
    2. The target customer profile
    3. A list of pros
    4. A list of cons

    {{ ctx.output_format }}
  "#
}
