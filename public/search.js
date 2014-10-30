$('.f-checkbox').click(function(e) {
  var query = $(this).data('query');
  var $fieldset = $(this).parent().parent();

  $.each(query, function(k,v){
    var $input = $('<input type="hidden">');
    $input.attr('name', k);
    $input.attr('value', v);
    $fieldset.append($input);
  });

  $('#search').submit();
})
