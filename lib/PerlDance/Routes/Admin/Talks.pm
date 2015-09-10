package PerlDance::Routes::Admin::Talks;

=head1 NAME

PerlDance::Routes::Admin::Talks - /admin/talks routes

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DataTransposeValidator;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Form;
use Try::Tiny;

=head1 ROUTES 

=head2 admin/talks

=cut

get '/admin/talks' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Talk Admin";

    $tokens->{talks} = rset('Talk')->search(
        {
            conferences_id => setting('conferences_id'),
        },
    );

    PerlDance::Routes::add_javascript( $tokens, '/js/admin.js' );

    template 'admin/talks', $tokens;
};

get '/admin/talks/create' => require_role admin => sub {
    my $tokens = {};

    $tokens->{title} = "Create Talk";

    my $form = form('create-update-talk');
    $form->reset;
    $form->fill(
        {
            accepted  => 1,
            confirmed => 0,
            lightning => 0,
            scheduled => 0,
        }
    );
    $tokens->{form} = $form;
    $tokens->{authors} = [ rset('User')->all];

    my @js_urls = ('/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js');

    PerlDance::Routes::add_javascript( $tokens, @js_urls );

    template 'admin/talks/create_update', $tokens;
};

post '/admin/talks/create' => require_role admin => sub {
    my $tokens = {};

    my $form   = form('create-update-talk');
    my $data = validator( $form->values, 'create-update-talk' );

    if ( $data->{valid} ) {
        my %values = %{ $data->{values} };
        $values{abstract} =~ s/\r\n/\n/g;

        rset('Talk')->create(
            {
                author_id      => $values{author},
                conferences_id => setting('conferences_id'),
                duration       => $values{duration},
                title          => $values{title},
                tags           => $values{tags} || '',
                abstract       => $values{abstract} || '',
                url            => $values{url} || '',
                comments       => $values{comments} || '',
                accepted       => $values{accepted} || 0,
                confirmed      => $values{confirmed} || 0,
                lightning      => $values{lightning} || 0,
                scheduled      => $values{scheduled} || 0,
                start_time     => $values{start_time} || undef,
                room           => $values{room} || '',
            }
        );
        return redirect '/admin/talks';
    }

    $tokens->{data} = $data;
    $tokens->{form} = $form;
    $tokens->{authors} = [ rset('User')->all];

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/talks/create_update', $tokens;
};

get '/admin/talks/delete/:id' => require_role admin => sub {
    try {
        rset('Talk')->find( param('id') )->delete;
    };
    redirect '/admin/talks';
};

get '/admin/talks/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $talk = rset('Talk')->find( param('id') );

    if ( !$talk ) {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('create-update-talk');
    $form->reset;

    $form->fill(
        {
            author          => $talk->author_id,
            duration        => $talk->duration,
            title           => $talk->title,
            tags            => $talk->tags,
            abstract        => $talk->abstract,
            url             => $talk->url,
            comments        => $talk->comments,
            accepted        => $talk->accepted,
            confirmed       => $talk->confirmed,
            lightning       => $talk->lightning,
            scheduled       => $talk->scheduled,
            start_time      => $talk->start_time,
            room            => $talk->room
        }
    );
    $tokens->{authors} = [ rset('User')->all ];
    $tokens->{form}    = $form;
    $tokens->{title}   = "Edit Talk";

    my @js_urls = ('/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js');

    PerlDance::Routes::add_javascript( $tokens, @js_urls );

    template 'admin/talks/create_update', $tokens;
};

post '/admin/talks/edit/:id' => require_role admin => sub {
    my $tokens = {};

    my $talk = rset('Talk')->find( param('id') );

    if ( !$talk ) {
        $tokens->{title} = "Talk Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    my $form = form('create-update-talk');
    my $data = validator( $form->values, 'create-update-talk' );

    if ( $data->{valid} ) {
        my %values = %{ $data->{values} };

        $values{abstract} =~ s/\r\n/\n/g;

        $talk->update(
            {
                author_id  => $values{author},
                duration   => $values{duration},
                title      => $values{title},
                tags       => $values{tags} || '',
                abstract   => $values{abstract} || '',
                url        => $values{url} || '',
                comments   => $values{comments} || '',
                accepted   => $values{accepted} || 0,
                confirmed  => $values{confirmed} || 0,
                lightning  => $values{lightning} || 0,
                scheduled  => $values{scheduled} || 0,
                start_time => $values{start_time} || undef,
                room       => $values{room} || '',

            }
        );
        return redirect '/admin/talks';
    }

    $tokens->{data} = $data;
    $tokens->{form} = $form;
    $tokens->{authors} = [ rset('User')->all];

    PerlDance::Routes::add_javascript(
        $tokens,
        '/js/bootstrap-datetimepicker.min.js',
        '/js/bootstrap-datetimepicker.config.js'
    );

    template 'admin/talks/create_update', $tokens;
};

true;
