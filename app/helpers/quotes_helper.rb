module QuotesHelper
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
