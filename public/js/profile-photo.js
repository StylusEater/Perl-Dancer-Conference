$(document).on('ready', function(){
    d = new Date();
    var img = $("img.photo");
    img.attr("src", img.attr("src") + "?" + d.getTime());
    $("#photo-upload").fileinput({
        uploadExtraData: { xsrf_token:
            $('head meta[name="xsrf-meta"]').attr('content') },
        uploadUrl: '/profile/photo/upload',
        uploadAsync: true,
        maxFileCount: 1,
        allowedFileTypes: ['image'],
        allowedFileExtensions: ['jpg', 'gif', 'png'],
        minImageHeight: 300,
        minImageWidth: 300,
        maxFileSize: 10240
    });
    $("#photo-upload").on('fileuploaded', function(e, data) {
        $(".upload-panel").addClass('hidden');
        console.log(data);
        function saveCoords(c) {
            $('#x').val(c.x);
            $('#y').val(c.y);
            $('#h').val(c.h);
            $('#w').val(c.w);
        };
        $("#new-photo").attr('src', data.response.src).Jcrop({
            aspectRatio: 1,
            minSize: [ 300, 300 ],
            boxWidth: 500,
            onChange: saveCoords,
            onSelect: saveCoords
        });
        $(".crop-panel").removeClass('hidden');
    });
});

