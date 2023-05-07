module IconsHelper
  def priority_icon(priority)
    case priority
    when "Highest", "High"
      content_tag(:i, "", class: "bi bi-arrow-up")
    when "Medium"
      content_tag(:i, "", class: "bi bi-arrow-left-right")
    when "Lowest", "Low"
      content_tag(:i, "", class: "bi bi-arrow-down")
    end
  end

  def status_icon(status)
    case status
    when "Waiting"
      content_tag(:i, "", class: "bi bi-hourglass-split")
    when "Accepted"
      content_tag(:i, "", class: "bi bi-check-circle")
    when "Declined"
      content_tag(:i, "", class: "bi bi-x-circle")
    end
  end

  def currency_icon(currency)
    case currency
    when "EUR"
      content_tag(:i, "", class: "bi bi-currency-euro")
    when "USD"
      content_tag(:i, "", class: "bi bi-currency-dollar")
    when "TND"
      content_tag(:i, "", class: "bi bi-cash")
    end
  end
end
