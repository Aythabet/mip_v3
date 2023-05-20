// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

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

// Projects "read more" section
