$(document).ready(function(){
	player_hit();
	player_stay();
	computer_play();



});

function player_hit() {
	$(document).on('click', '#hit_form', function(){
		$.ajax({
			url : '/game/player/hit',
			type : 'POST',
			success : function(response){
				$('#game_div').replaceWith($(response).find('#game_div'));
			}

		});

		return false;
		

	});


}


function player_stay(){
	$(document).on('click', '#stay_form', function(){
		$.ajax({
			url: 'game/player/stay',
			type : 'POST',
			success: function(response){
				$('#game_div').replaceWith($(response).find('#game_div'));
			}

		});

		return false;

	});



}

function computer_play(){
	$(document).on('click', '#computer_form', function(){
		$.ajax({
			url: '/game/computer/computer_move',
			type: 'TYPE',
			success: function(response){
				$('#game_div').replaceWith($(response).find('#game_div'));
			}
		});

		return false;


	});


}


