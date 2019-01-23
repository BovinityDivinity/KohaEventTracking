package Koha::Plugin::EventTracking;
use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;

our $metadata = {
    name            => 'Event Tracking',
    author          => 'Michael A Springer',
    date_authored   => '2019-01-16',
    date_updated    => '2019-01-19',
    minimum_version => undef,
    maximum_version => undef,
    version         => '0.8',
    description     => 'Event tracking for LCLS',      
};

sub new {
    my ($class, $args) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool() {
    my ($self, $args) = @_;
    my $cgi = $self->{'cgi'};    
    my $op = $cgi->param('op');   
    my $dbh = C4::Context->dbh;
    my $sqlstatement;
    my $sth; 
    my @results;

    if ($op eq "submitevent") {
        my $eventname = $cgi->param('title');
        my $date = $cgi->param('date');        
        my $branch = $cgi->param('branch');        
        my $description = $cgi->param('description');
        my $adults = $cgi->param('adults');
        my $children = $cgi->param('children');                

        $sqlstatement = "INSERT INTO event_tracking (eventname, eventdate, location, description, adultattendance, childattendance) VALUES (?,?,?,?,?,?);";        
        $sth = $dbh->prepare($sqlstatement);        
        $sth->execute($eventname, $date, $branch, $description, $adults, $children) or die $dbh->errstr;   
                       
        my $template = $self->get_template({file => 'eventhome.tt'});
        $template->param(message => "Your event has been submitted! Thank you!");

        print $cgi->header();
        print $template->output();        
    }
    elsif ($op eq "addevent") {         
        my $userbranch = C4::Context->userenv->{"branch"} || '';
        my $template = $self->get_template({file => 'evententry.tt'}); 
        $template->param(branchshort => $userbranch);

        print $cgi->header();
        print $template->output();     
    }    
    elsif ($op eq "viewevents") {
        $sqlstatement = "SELECT * FROM event_tracking;";
        $sth = $dbh->prepare($sqlstatement);        
        $sth->execute() or die $dbh->errstr;         
        @results  = $sth->fetchall_arrayref({});
       
        my $template = $self->get_template({file => 'eventview.tt'});              
        $template->param(eventlist => @results);

        print $cgi->header();
        print $template->output();     
    }
    elsif ($op eq "delevent") {
        my $delid = $cgi->param('id');
        $sqlstatement = "DELETE FROM event_tracking WHERE eventnumber = ? LIMIT 1;";
        $sth = $dbh->prepare($sqlstatement);
        $sth->execute($delid) or die $dbh->errstr;

        $sqlstatement = "SELECT * FROM event_tracking;";
        $sth = $dbh->prepare($sqlstatement);        
        $sth->execute() or die $dbh->errstr;          
        @results  = $sth->fetchall_arrayref({});
       
        my $template = $self->get_template({file => 'eventview.tt'});              
        $template->param(eventlist => @results);

        print $cgi->header();
        print $template->output();     
    }    
    else {        
        my $template = $self->get_template({file => 'eventhome.tt'});
    
        print $cgi->header();
        print $template->output();
    }
}

sub install() {
    my ($self, $args) = @_;

    my $intranetnav = C4::Context->preference('IntranetNav');

    $intranetnav .= q(<li class="nav"><a href="/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::EventTracking&method=tool">Event Tracking</a></li>);

    C4::Context->set_preference('IntranetNav', $intranetnav);

    return C4::Context->dbh->do("CREATE TABLE event_tracking (
        `eventnumber` INT NOT NULL AUTO_INCREMENT,
        `eventname` VARCHAR(100),
        `eventdate` DATE,
        `location` VARCHAR(10),
        `description` VARCHAR(500),
        `adultattendance` INT,
        `childattendance` INT,
        PRIMARY KEY (eventnumber)) ENGINE = INNODB;");    
}

sub uninstall() {
    my ($self, $args) = @_;   

    return C4::Context->dbh->do("DROP TABLE event_tracking");
}
