#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Test::More tests => 5;
use Test::MockModule;

use t::lib::TestBuilder;
use t::lib::Mocks;

use Koha::ArticleRequests;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

subtest 'request() tests' => sub {

    plan tests => 3;

    $schema->storage->txn_begin;

    my $patron = $builder->build_object({ class => 'Koha::Patrons' });
    my $biblio = $builder->build_sample_biblio;

    my $ar_mock = Test::MockModule->new('Koha::ArticleRequest');
    $ar_mock->mock( 'notify', sub { ok( 1, '->notify() called' ); } );

    my $ar = Koha::ArticleRequest->new(
        {
            borrowernumber => $patron->id,
            biblionumber   => $biblio->id,
        }
    );

    $ar->request()->discard_changes;

    is( $ar->status, Koha::ArticleRequest::Status::Requested );
    ok( defined $ar->created_on, 'created_on is set' );

    $schema->storage->txn_rollback;
};

subtest 'set_pending() tests' => sub {

    plan tests => 3;

    $schema->storage->txn_begin;

    my $patron = $builder->build_object({ class => 'Koha::Patrons' });
    my $biblio = $builder->build_sample_biblio;

    my $ar_mock = Test::MockModule->new('Koha::ArticleRequest');
    $ar_mock->mock( 'notify', sub { ok( 1, '->notify() called' ); } );

    my $ar = Koha::ArticleRequest->new(
        {
            borrowernumber => $patron->id,
            biblionumber   => $biblio->id,
        }
    );

    $ar->set_pending()->discard_changes;

    is( $ar->status, Koha::ArticleRequest::Status::Pending );
    ok( defined $ar->created_on, 'created_on is set' );

    $schema->storage->txn_rollback;
};

subtest 'process() tests' => sub {

    plan tests => 2;

    $schema->storage->txn_begin;

    my $ar_mock = Test::MockModule->new('Koha::ArticleRequest');
    $ar_mock->mock( 'notify', sub { ok( 1, '->notify() called' ); } );

    my $ar = $builder->build_object(
        {   class => 'Koha::ArticleRequests',
            value => { status => Koha::ArticleRequest::Status::Requested }
        }
    );

    $ar->process()->discard_changes;

    is( $ar->status, Koha::ArticleRequest::Status::Processing );

    $schema->storage->txn_rollback;
};

subtest 'complete() tests' => sub {

    plan tests => 2;

    $schema->storage->txn_begin;

    my $ar_mock = Test::MockModule->new('Koha::ArticleRequest');
    $ar_mock->mock( 'notify', sub { ok( 1, '->notify() called' ); } );

    my $ar = $builder->build_object(
        {   class => 'Koha::ArticleRequests',
            value => { status => Koha::ArticleRequest::Status::Requested }
        }
    );

    $ar->complete()->discard_changes;

    is( $ar->status, Koha::ArticleRequest::Status::Completed );

    $schema->storage->txn_rollback;
};

subtest 'cancel() tests' => sub {

    plan tests => 4;

    $schema->storage->txn_begin;

    my $ar_mock = Test::MockModule->new('Koha::ArticleRequest');
    $ar_mock->mock( 'notify', sub { ok( 1, '->notify() called' ); } );

    my $ar = $builder->build_object(
        {   class => 'Koha::ArticleRequests',
            value => { status => Koha::ArticleRequest::Status::Requested }
        }
    );

    my $reason = "Hey, ho";
    my $notes  = "Let's go!";

    $ar->cancel({ cancellation_reason => $reason, notes => $notes })->discard_changes;

    is( $ar->status, Koha::ArticleRequest::Status::Canceled );
    is( $ar->cancellation_reason, $reason, 'Cancellation reason stored correctly' );
    is( $ar->notes, $notes, 'Notes stored correctly' );

    $schema->storage->txn_rollback;
};