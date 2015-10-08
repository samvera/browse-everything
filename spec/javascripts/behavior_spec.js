describe("toggleCheckbox", function() { 

it("toggles the value between 1 and 0", function() {
    var html = '<input type="checkbox" name="select_all" id="select_all" value="0" class="ev-select-all"/>';
    var toggled = $.fn.browseEverything.toggleCheckbox($(html)[0]);
    expect($(toggled)[0].value).toEqual("1");
  });

});
