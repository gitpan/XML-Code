package XML::Code;

use vars qw ($VERSION);

$VERSION = '0.2';

sub new{
	my $who = shift;
	my $class = ref ($who) || $who;
	my $this = {
	   '<name>' => shift,
	   '<children>' => []};
	return bless $this, $class;
}

sub version{
	my $this = shift;
	$this->{'<version>'} = shift;
}

sub encoding{
	my $this = shift;
	$this->{'<encoding>'} = shift;	
   $this->{'<version>'} = '1.0' unless $this->{'<version>'}; 
}

sub stylesheet{
	my $this = shift;
	$this->{'<stylesheet>'} = shift;	
}

sub comment{
	my $this = shift;
	my $comment = {
	   '<name>' => '!',
	   '<text>' => shift};
	bless $comment;
	$this->add_child ($comment);
}

sub pi{
	my $this = shift;
	my $pi = {
	   '<name>' => '?',
	   '<text>' => shift};
	bless $pi;
	$this->add_child ($pi);
}

sub name{
	my $this = shift;
	return $this->{'<name>'};
}

sub add_child{
	my $this = shift;
	my $children = shift;
	push @{$this->{'<children>'}}, $children; 
}

sub set_text{
	my $this = shift;
	my $text = shift;
	$this->{'<text>'} = $text;
}

sub text{
   my $this = shift;
   return $this->{'text'};
}

sub code{
	my $this = shift;
	my $tab_level = shift || 0;
	my $suppress_tab = shift || 0;
	
	$suppress_tab = 1 if $tab_level == -1;

	my $tab = "\t" x ($tab_level) unless $suppress_tab;
	
	my $name = $this->{'<name>'};
	my $text = $this->{'<text>'} || '';
	
	my $code = '';
	
	my $prolog;
	$prolog = " version=\"$this->{'<version>'}\"" if $this->{'<version>'};
	$prolog .= " encoding=\"$this->{'<encoding>'}\"" if $this->{'<encoding>'};
	$code = "<?xml$prolog?>\n" if $prolog;
	$code .= "<?xml-stylesheet type=\"text/xsl\" href=\"$this->{'<stylesheet>'}\"?>\n"
		if $this->{'<stylesheet>'};
	
	if ($name eq '!'){
	   $code .= "$tab<!-- " . escape ($text) . " -->\n";
	}
	
	elsif ($name eq '?'){
	   $code .= "$tab<?" . escape ($text) . "?>\n";
	}
	
	else{  	
    	my $children = $this->{'<children>'};
    	
    	$code .= "$tab<$name";
    	foreach my $attribute (keys %$this){
    		$code .= " $attribute=\"" . escape ($this->{$attribute}) . "\"" 
    		   unless $attribute =~ m{^<};
    	}
    	
    	if (scalar @$children){
    	   $code .= $text ? ">$text" : ">\n"; 
    	   for (my $count = 0; $count != scalar @$children; $count++){
    	   	   $code .= $$children[$count]->code ($tab_level != -1 ? $tab_level + 1 : -1, 
			   	   $count == 0 && length ($text) ? 1 : 0);
    	   }
    	   $code .= "$tab</$this->{'<name>'}>\n";
    	}
    	else{
    	   $code .= $text ? ">" . escape ($text) . "</$name>\n" : "/>\n"; 
    	}
	}
	
	return $code;
}

sub escape{
	my $text = shift;
	$text =~ s{\&}{\&amp;}gm;
	$text =~ s{<}{\&lt;}gm;
	$text =~ s{>}{\&gt;}gm;
	return $text;
}

return 1;

__END__ 

=head1 NAME

XML::Code - Perl module for converting XML hash structures into plain text.

=head1 SYNOPSIS

use XML::Code;

my $content = new XML::Code ('tag-name');
$content->{'attribute-name'} = 'attribute valuå';

$sub_content = new XML::Code ('sub-content');
$content->add_child ($sub_content);
$sub_content->set_text ('text node');

print $content->code();

=head1 EXTENDED SYNOPSIS

use XML::Code;

# Creating top XML node.

my $content = new XML::Code ('content');

# Requesting <?xml?> and <?xml-stylesheet?> directives.

$content->version ('1.0');
$content->encoding ('Windows-1251');
$content->stylesheet ('test.xslt');

# Adding attribute.

$content->{'level'} = 'top';

# Adding child node.

$sub_content = new XML::Code ('sub-content');
$content->add_child ($sub_content);

# Setting text content of a node.

$sub_content->set_text ('inner text');

# Adding anonimous child node.

$sub2->add_child (XML::Code->new ('sub3'));

# Inserting comments and processing instuctions.

$content->comment ('This is a comment & more');
$content->pi ("instruction intro=\"hi\"");

# Producing plain text XML code.

print $content->code();

=head1 DESCRIPTION

XML::Code module is designed to enable simple object-oriented procedure of creating XML data.
As soon as a programmer realizes that XML and OOP are kindred and have sibling connections 
he or she wants to use objects instead of plain text in the phase of producing XML files.
XML::Code allows thinking of XML tags as of nested named objects and expects XML::Code::code()
method be called to produce plain text XML.

XML::Code only produce code: that means the module does not provide methods of random access
(like XPath does) to the XML structure though tree elements are fully accessible as nested hashes.

=head1 METHODS

=head2 Creating nodes

How to create XML::Code nodes.

=head3 new() (Constructor) 

Creates an XML node and return corresponding blessed reference. Call of new() expects that you
give tag name as an argument of new(). 

=head3 comment() (Constructor)

Creates comment node. This method should be normally called as a method of existing XML::Code object.

=head3 pi() (Constructor)

Creates a node of prosession instruction. Preferably should be called with existing XML::Code object.

=head2 Creating attributes and content

=head3 Attributes

If you have a node, you may access its attributes as if you have a hash reference:

$tag = new XML::Code ('tag-name');
$tag->{'tag-attribute'} = 'attribute value';
print $tag->{'tag-attribute'};

=head3 set_text()

Sets some text value of the node. Note that you still may add children to the node.

=head3 add_child()

Adds a child to the current XML node. This method takes a reference to existing XML::Code object.
It is also possible to construct unreferenced child object while you call add_child().
Thus two following lines of Perl code are equivalent (the difference is that you can still manipulate 
child object in the first case):

1. my $child = new XML::Code ('child'); $parent->add_child ($child);
2. $parent->add_child (new XML::Code ('child'));

=head2 Getting information

=head3 name()

Returns a tag name of a node.

=head3 text()

If the node is a text-node, returns its text value. Note that this method does not evaluate
text value of child nodes if they are present.

=head2 XML extras 

Code formatting operations.

=head3 version() and encoding()

When some value is passed to one (or both) of these methods you will get XML header directives 
in the resulting code (i. e. code generated by code()).

The following Perl code 

my $xml = new XML::Code ('top');
$xml->version ("1.0");
$xml->encoding ("Windows-1251");
print $xml->code; 
 
will produce this XML code:

<?xml version="1.0" encoding="Windows-1251"?>
<top/>

Note that setting version number may be omitted, in such a case it will be set to "1.0".
Nevertheless you have to set at least either version number or encoding name to have <?xml?> prolog
in the output. Normally these methods shold be applied to a top-level tag.

=head3 stylesheet() 

Inserts <?xml-stylesheet?> instruction into resulting code so that resulting XML file may be
transformed with some external XSLT-file.

=head2 Generating code

=head2 code()

Generates plain text XML code.

$xml->code() produces tab-formatted output while
$xml->code (-1) suppresses any tab spaces in the beging of lines.

You can also pass $xml->code() method any positive integer number: is this case output code
will be right-shifted to that number of "\t" characters.

=head1 AUTHOR

Andrew Shitov <andy@shitov.ru>

