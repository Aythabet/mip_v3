import flatpickr from "flatpickr";

document.addEventListener("DOMContentLoaded", function () {
  flatpickr("#flatpickr-date", {
    dateFormat: "Y-m-d",
    maxDate: "today",
  });
});

// Slider homepage timer to move
$(document).ready(function () {
  $("#projectSlider").carousel({
    interval: 5000, // Adjust the interval time (in milliseconds) as needed
  });
});

document.addEventListener("DOMContentLoaded", function () {
  // Modal Add Selling Price for the projects
  $(document).ready(function () {
    $("#addSellingPriceLink").click(function () {
      $("#editSellingPriceModal").modal("show");
    });
  });

  // Dismiss Selling Price Modal
  var dismissButton = document.getElementById("dismissButton");
  if (dismissButton) {
    dismissButton.addEventListener("click", function () {
      $("#editSellingPriceModal").modal("hide");
    });
  }
});

/*Quotes Modal*/
document.addEventListener("DOMContentLoaded", function () {
  $(document).ready(function () {
    $("#addQuoteLink").click(function () {
      $("#AddQuoteModal").modal("show");
    });
  });

  // Dismiss Modal
  var dismissButton = document.getElementById("dismissButton");
  if (dismissButton) {
    dismissButton.addEventListener("click", function () {
      $("#AddQuoteModal").modal("hide");
    });
  }
});

/*Vacations Modal*/
document.addEventListener("DOMContentLoaded", function () {
  $(document).ready(function () {
    $("#addVacationLink").click(function () {
      $("#AddVacationModal").modal("show");
    });
  });

  // Dismiss Modal
  var dismissButton = document.getElementById("dismissButton");
  if (dismissButton) {
    dismissButton.addEventListener("click", function () {
      $("#AddVacationModal").modal("hide");
    });
  }
});

/*Vacations days Modal*/
document.addEventListener("DOMContentLoaded", function () {
  $(document).ready(function () {
    $("#addVacationDaysLink").click(function () {
      $("#addVacationDaysModal").modal("show");
    });
  });

  // Dismiss Modal
  var dismissButton = document.getElementById("dismissButton");
  if (dismissButton) {
    dismissButton.addEventListener("click", function () {
      $("#addVacationDaysModal").modal("hide");
    });
  }
});

// Get the maximum height among all cards (Daily reports)
const maxHeight = Math.max(
  ...Array.from(
    document.querySelectorAll(".card-custom"),
    (card) => card.offsetHeight
  )
);

// Set the height of all cards to the maximum height
document.querySelectorAll(".card-custom").forEach((card) => {
  card.style.height = `${maxHeight}px`;
});
