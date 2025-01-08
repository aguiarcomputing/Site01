(function ($) {
    "use strict";

    // Spinner
    var spinner = function () {
        setTimeout(function () {
            if ($('#spinner').length > 0) {
                $('#spinner').removeClass('show');
            }
        }, 1);
    };
    spinner();


    // Initiate the wowjs
    new WOW().init();


    // Back to top button
    $(window).scroll(function () {
        if ($(this).scrollTop() > 300) {
            $('.back-to-top').fadeIn('slow');
        } else {
            $('.back-to-top').fadeOut('slow');
        }
    });
    $('.back-to-top').click(function () {
        $('html, body').animate({ scrollTop: 0 }, 1500, 'easeInOutExpo');
        return false;
    });


    // Team carousel
    $(".team-carousel").owlCarousel({
        autoplay: true,
        smartSpeed: 1000,
        center: false,
        dots: false,
        loop: true,
        margin: 50,
        nav: true,
        navText: [
            '<i class="bi bi-arrow-left"></i>',
            '<i class="bi bi-arrow-right"></i>'
        ],
        responsiveClass: true,
        responsive: {
            0: {
                items: 1
            },
            768: {
                items: 2
            },
            992: {
                items: 3
            }
        }
    });


    // Testimonial carousel

    $(".testimonial-carousel").owlCarousel({
        autoplay: true,
        smartSpeed: 1500,
        center: true,
        dots: true,
        loop: true,
        margin: 0,
        nav: true,
        navText: false,
        responsiveClass: true,
        responsive: {
            0: {
                items: 1
            },
            576: {
                items: 1
            },
            768: {
                items: 2
            },
            992: {
                items: 3
            }
        }
    });


    // Fact Counter

    $(document).ready(function () {
        $('.counter-value').each(function () {
            $(this).prop('Counter', 0).animate({
                Counter: $(this).text()
            }, {
                duration: 2000,
                easing: 'easeInQuad',
                step: function (now) {
                    $(this).text(Math.ceil(now));
                }
            });
        });
    });



})(jQuery);




function SendEmail() {
    var nome = $('#seunome').val();
    var email = $('#seuemail').val();
    var projeto = $('#projeto').val();
    var mensagem = $('#mensagem').val();

    var mensagemcompleta = '<b>Projeto:</b>' + projeto + '<br /><b>Mensagem</b>' + mensagem;
    var msg = '{"Messages": [{"From": {"Email": "jbdesenvolvedor@gmail.com","Name": "Site Orçamento"},"To": [{"Email": "' + email + '","Name": "Cliente"}],"Subject": "Contato via site!","TextPart": "' + mensagemcompleta + '","HTMLPart": "' + mensagemcompleta + '"}]}';

    $.ajax({
        url: 'https://api.mailjet.com/v3.1/send',
        headers: {
            'Authorization': 'Basic ODIwOTgzZGE1NWM5NjQ5MDQwNzI0NDUwNTIyYmQxYzI6MWZmNDgwN2IxMDVjY2IxZTM3YWZjYTU3ZjE2NjhlYjA=',
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        method: 'POST',
        dataType: 'json',
        data: msg,
        success: function (data) {
            console.log('succes: ' + data);
        },
        error: function (data) {
            console.log('erro: ' + data);
        }
    });
}