use ExtUtils::MakeMaker;

my $mm = new MM
 (
  {
   AUTHOR => "Daniel Ruoso <daniel\@ruoso.com>",
   ABSTRACT => "Perl Oak Component Tree",
   NAME => "Oak::Filer::DBI",
   VERSION => "1.8",
   PREREQ_PM => 
   {
    'Oak::Filer'   => '0',
    'Error' => '0.15',
   }
  }
 );

$mm->flush;
