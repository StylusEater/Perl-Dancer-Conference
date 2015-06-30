package PerlDance::Routes;

=head1 NAME

PerlDance::Routes - routes for PerlDance conference application

=cut

use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Interchange6;
use Dancer::Plugin::Interchange6::Routes;
use Try::Tiny;

use PerlDance::Routes::Account;
use PerlDance::Routes::Talk;

=head1 ROUTES

See also: L<PerlDance::Routes::Account>, L<PerlDance::Routes::Talk>

=head2 get /

Home page

=cut

get '/' => sub {
    my $tokens = {};

    add_speakers_tokens($tokens);

    my $nav = shop_navigation->find( { uri => 'tickets' } );
    $tokens->{tickets} = [ $nav->products->active->hri->all ];

    $tokens->{title} = "Vienna Austria October 2015";

    add_javascript( $tokens, "//maps.google.com/maps/api/js?sensor=false",
        "/js/index.js" );

    template 'index', $tokens;
};

=head2 get /speakers

Speaker list

=cut

get '/speakers' => sub {
    my $tokens = {};

    add_navigation_tokens( $tokens );
    add_speakers_tokens($tokens);

    $tokens->{title} = "Speakers";

    template 'speakers', $tokens;
};

=head2 get /speakers/{id}.*

Individual speaker

=cut

get qr{/speakers/(?<id>\d+).*} => sub {
    my $users_id = captures->{id};
    my $tokens = {};

    $tokens->{user} = shop_user->search(
        {
            'me.users_id'                         => $users_id,
            'conferences_attended.conferences_id' => setting('conferences_id'),
            'addresses.type'                      => 'primary',
        },
        {
            prefetch =>
              [ { addresses => 'country', }, 'photo' ],
            join => 'conferences_attended',
            rows => 1,
        }
    )->first;

    if ( !$tokens->{user} ) {
        $tokens->{title} = "Speaker Not Found";
        status 'not_found';
        return template '404', $tokens;
    }

    $tokens->{talks} = $tokens->{user}->search_related(
        'talks_authored',
        {
            conferences_id => setting('conferences_id'),
            accepted       => 1,
            confirmed      => 1,
        }
    );

    $tokens->{has_talks} = 1 if $tokens->{talks}->has_rows;

    $tokens->{title} = $tokens->{user}->name;

    template 'speaker', $tokens;
};

=head2 get /sponsors

Sponsor list

=cut

get '/sponsors' => sub {
    my $tokens = {};

    add_navigation_tokens( $tokens );

    template 'sponsors', $tokens;
};

=head2 get /sponsoring

Be a sponsor

=cut

get '/sponsoring' => sub {
    my $tokens = {};

    add_navigation_tokens($tokens);

    template 'sponsoring', $tokens;
};

=head2 get /tickets

Conference tickets

=cut

get '/tickets' => sub {
    my $tokens = {};

    add_navigation_tokens($tokens);

    $tokens->{tickets} = [ shop_navigation( { uri => 'tickets' } )
          ->products->active->hri->all ];

    template 'tickets', $tokens;
};

=head2 shop_setup_routes

L<Dancer::Plugin::Interchange6::Routes/shop_setup_routes>

=cut

shop_setup_routes;

=head2 not_found

404

=cut

any qr{.*} => sub {
    my $tokens = {};

    $tokens->{title} = "Not Found";

    status 'not_found';
    template '404', $tokens;
};

=head1 METHODS

=head2 add_javascript($tokens, @js_urls);

=cut

sub add_javascript {
    my $tokens = shift;
    foreach my $src ( @_ ) {
        push @{ $tokens->{"extra-js"} }, { src => $src };
    }
}

=head2 add_navigation_tokens

Add title and description tokens;

=cut

sub add_navigation_tokens {
    my $tokens = shift;

    ( my $uri = request->path ) =~ s{^/+}{};
    my $nav = shop_navigation->find( { uri => $uri } );

    $tokens->{title}       = $nav->name;
    $tokens->{description} = $nav->description;
}

=head2 add_speakers_tokens($tokens);

Add tokens needed by speakers fragment

=cut

sub add_speakers_tokens {
    my $tokens = shift;

    my @speakers = shop_user->search(
        {
            'addresses.type'                      => 'primary',
            'conferences_attended.conferences_id' => setting('conferences_id'),
            -or                                   => {
                'talks_authored.accepted'  => 1,
                'talks_authored.confirmed' => 1,
                -and                       => {
                    'attribute.name' => 'speaker',
                    'attribute.type' => 'boolean',
                },
            },
        },
        {
            prefetch => [ { addresses => 'country', }, 'photo' ],
            join     => [
                'conferences_attended', 'talks_authored',
                { user_attributes => 'attribute' }
            ],
        }
    )->all;

    my @grid;
    while ( my @row = splice( @speakers, 0, 4 ) ) {
        push @grid, +{ row => \@row };
    }

    $tokens->{speakers} = \@grid;
}

true;