use Modern::Perl;

return {
    bug_number => "31713",
    description => "Add ACCOUNTS_SUMMARY slip notice",
    up => sub {
        my ($args) = @_;
        my ($dbh, $out) = @$args{qw(dbh out)};

        my $slip_content = <<~'END_CONTENT';
[% USE Branches %]
[% USE Koha %]
[% USE KohaDates %]
[% USE Price %]
[% PROCESS 'accounts.inc' %]
<table>
  [% IF ( Koha.Preference('LibraryName') ) %]
    <tr>
      <th colspan='4' class='centerednames'>
        <h1>[% Koha.Preference('LibraryName') | html %]</h1>
      </th>
    </tr>
  [% END %]

  <tr>
    <th colspan='4' class='centerednames'>
      <h2>[% Branches.GetName( borrower.branchcode ) | html %]</h2>
    </th>
  </tr>

  <tr>
    <th colspan='4' class='centerednames'>
      <h3>Outstanding accounts</h3>
    </th>
  </tr>

  <tr>
    <th colspan='4' class='centerednames'>
      <h4>Debts</h4>
    </th>
  </tr>
  [% IF borrower.account.outstanding_debits.total_outstanding %]
  <tr>
    <th>Date</th>
    <th>Charge</th>
    <th>Amount</th>
    <th>Outstanding</th>
  </tr>
  [% FOREACH debit IN borrower.account.outstanding_debits %]
  <tr>
    <td>[% debit.date | $KohaDates %]</td>
    <td>
      [% PROCESS account_type_description account=debit %]
      [%- IF debit.description %], [% debit.description | html %][% END %]
    </td>
    <td class='debit'>[% debit.amount | $Price %]</td>
    <td class='debit'>[% debit.amountoutstanding | $Price %]</td>
  </tr>
  [% END %]
  [% ELSE %]
  <tr>
    <td colspan='4'>There are no outstanding debts on your account</td>
  </tr>
  [% END %]

  <tr>
    <th colspan='4' class='centerednames'>
      <h4>Credits</h4>
    </th>
  </tr>
  [% IF borrower.account.outstanding_credits.total_outstanding %]
  <tr>
    <th>Date</th>
    <th>Credit</th>
    <th>Amount</th>
    <th>Outstanding</th>
  </tr>
  [% FOREACH credit IN borrower.account.outstanding_credits %]
  <tr>
    <td>[% credit.date | $KohaDates %]</td>
    <td>
      [% PROCESS account_type_description account=credit %]
      [%- IF credit.description %], [% credit.description | html %][% END %]
    </td>
    <td class='credit'>[% credit.amount | $Price %]</td>
    <td class='credit'>[% credit.amountoutstanding | $Price %]</td>
  </tr>
  [% END %]
  [% ELSE %]
  <tr>
    <td colspan='4'>There are no outstanding credits on your account</td>
  </tr>
  [% END %]

  <tfoot>
    <tr>
      <td colspan='3'>Total outstanding dues as of [% today | $KohaDates  %]: </td>
      [% IF ( borrower.account.balance <= 0 ) %]<td class='credit'>[% ELSE %]<td class='debit'>[% END %][% borrower.account.balance | $Price %]</td>
    </tr>
  </tfoot>
</table>
END_CONTENT

        $dbh->do(qq{
           INSERT IGNORE INTO letter ( module, code, branchcode, name, is_html, title, content, message_transport_type, lang)
           VALUES ( 'members', 'ACCOUNTS_SUMMARY', '', 'Account balance slip', 1, 'Account summary for [% borrower.firstname %] [% borrower.surname %]', "$slip_content", 'print', 'default' )
        });
        say $out "Notice added";
    },
};