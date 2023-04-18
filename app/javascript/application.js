// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails


document.addEventListener("DOMContentLoaded", function() {
  // Modal Add Selling Price for the projects
  $(document).ready(function() {
    $('#addSellingPriceLink').click(function() {
      $('#editSellingPriceModal').modal('show');
    });
  });

  // Dismiss Selling Price Modal
  var dismissButton = document.getElementById("dismissButton");
  if (dismissButton) {
    dismissButton.addEventListener("click", function() {
      $('#editSellingPriceModal').modal('hide');
    });
  }
});
