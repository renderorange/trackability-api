use Plack::Builder;
use Trackability::API;

builder {
    # mount the app
    mount '/' => Trackability::API->to_app,

    # middleware
    enable 'TrailingSlashKiller',
};

__END__
