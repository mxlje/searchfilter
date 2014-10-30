$('.f-checkbox').click(function(e) {
  window.location = "/search"+ $(this).data('query');
})