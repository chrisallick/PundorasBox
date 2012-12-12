checkValid = function( pString, needle ) {
    if ( !pString || pString.length == 0 || pString.length > 60 || pString.split(' ').join('').indexOf( needle ) == -1  ) {
        return false;
    }
    return /[^\s]+/.test(pString);
}

clear = function() {
	clearTimeout(t);
	$("#error").html("");
}

submitEntry = function() {
	clear();
	var entry = $("#entry").val();
	if( checkValid( $("#entry").val().toLowerCase(), $("h1").html().toLowerCase() ) ) {
		$.ajax({
  			type: "POST",
  			url: "/add",
  			dataType: "json",
  			data: { "word": "fish", "pun": entry},
  			beforeSend: function() {
				$("#loading").css("display","block");
			}
		}).done( function( resp ) {
  			if( resp && resp["result"] == "success") {
				$("#examples").append("<p>"+resp["pun"]+"</p>");
			} else if( resp && resp["result"] == "fail" ) {
				$("#error").html( resp["msg"] ).show();
				t = setTimeout( clear, 3000 );
			}
			$("#entry").val("");
			$("#loading").css("display","none");
		});
	} else {
		$("#error").html("Entry must contain pun. Limit is 60 characters.").show();
		t = setTimeout( clear, 3000 );
	}
}

var t;
$(document).ready( function() {
	$("form").submit(function(event){
		event.preventDefault();
		submitEntry();
	});

	$("#entry").click(function(event){
		event.preventDefault();
		clear();
	});
});