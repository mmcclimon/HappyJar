$(function() {
  $('select.dk').dropkick();
    $('#memoryArea').keyup(function() {
    var areaLen = $('#memoryArea').val().length;
    var charsleft = 1000 - areaLen;
    $('#charsLeft').html(charsleft);
  });
});
