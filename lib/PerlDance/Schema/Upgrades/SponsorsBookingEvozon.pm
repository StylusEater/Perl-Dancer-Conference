package PerlDance::Schema::Upgrades::SponsorsBookingEvozon;

use Moo;
use Types::Standard qw/InstanceOf/;

use DateTime;

has schema => (
    is => 'ro',
    isa => InstanceOf['PerlDance::Schema'],
    required => 1,
);

has sponsor_levels => (
    is => 'ro',
    default => sub {
        return [
            {
                name => 'Diamond Sponsor',
                uri => 'sponsors/diamond',
                priority => 50,
            },
            {
                name => 'Gold Sponsor',
                uri => 'sponsors/gold',
                priority => 40,
                sponsors => [
                    {
                        title => 'Booking',
                        summary => '[Booking](https://www.booking.com/)',
                        uri => 'https://www.booking.com/',
                        media => {
                            file => 'img/booking-logo.jpg',
                            mime_type => 'image/jpg',
                        },
                    },
                ],

            },
            {
                name => 'Silver Sponsor',
                uri => 'sponsors/silver',
                priority => 30,
                sponsors => [
                    {
                        title => 'Evozon',
                        summary => '[Evozon](https://www.evozon.com/)',
                        content => q|
Headquartered in Cluj Napoca, Transylvania, the Perl team at Evozon has over 80 developers, and we are of very few companies that develop Perl web applications in-house for 10 years. We have in-depth experience developing Perl using a wide range of frameworks. Evozon offers custom software solutions, business analysis and project management across the widest possible range of technologies and platforms for web and mobile. Our deep Perl knowledge comes as much from experience as from passion.

Evozon is also actively involved in the development of the Perl community including creating and sponsoring the Cluj Perl Mongers group Cluj.pm (www.cluj.pm), and YAPC Europe, London Perl Workshop, QA Hackathon, German Perl Workshop and contributing to CPAN. And by demonstrating a constant passion and support for the Perl Community, we were given the honor to host YAPC::EU 2016 in Cluj-Napoca. Check out the event aftermovie on [YouTube](https://youtu.be/cVg7wVLk0p4).

If you want to learn more about Evozon or wish to get in touch with us, visit [www.evozon.com](https://www.evozon.com/) for more details.|,
                        uri => 'https://www.evozon.com/',
                        media => {
                            file => 'img/evozon.png',
                            mime_type => 'image/png',
                        },
                    },
                ],

            },
            {
                name => 'Bronze Sponsor',
                uri => 'sponsors/bronze',
                priority => 20,
            },
            {
                name => 'Special Sponsor',
                uri => 'sponsors/special',
                priority => 10,
            },
        ];
    }
);

sub upgrade {
    my $self = shift;
    my $schema = $self->schema;

    # create message type for sponsors
    my $message_type = $schema->resultset('MessageType')->search({
        name => 'sponsors',
    })->single;

    # add navigation entries for the different sponsor types
    my $sponsor_nav = $schema->resultset('Navigation')->find({uri => 'sponsors'});

    for my $level (@{$self->sponsor_levels}) {
        my $nav = $schema->resultset('Navigation')->find_or_create({
            parent_id => $sponsor_nav->id,
            name => $level->{name},
            uri => $level->{uri},
            priority => $level->{priority},
        });

        my $sponsors = $level->{sponsors} || [];

        for my $sponsor_msg (@{ $level->{sponsors} || []}) {
            $sponsor_msg->{message_types_id} = $message_type->id;
            $sponsor_msg->{content} ||= '';
            my $media_info = delete $sponsor_msg->{media};
            my $msg;
            if ($msg = $schema->resultset('Message')->find({title => $sponsor_msg->{title}})) {
                $msg->update($sponsor_msg);
                next;
            }

            $msg = $schema->resultset('Message')->create($sponsor_msg);
            $msg->create_related('navigation_messages', {navigation_id => $nav->id});

            if ($media_info) {
                # create media entry
                my $media_type =
                    $schema->resultset('MediaType')->find( { type => 'image' } );

                $msg->add_to_media({
                    %$media_info, media_type => { type => 'image' }
                });
            }
        }
    }
}

sub clear {
    my $self = shift;
    my $schema = $self->schema;

}

1;

