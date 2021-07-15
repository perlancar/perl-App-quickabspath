package App::quickabspath;

# AUTHORITY
# DATE
# DIST
# VERSION

sub quick_abs_path
{
    my $start = @_ ? shift : '.';
    my($dotdots, $cwd, @pst, @cst, $dir, @tst);

    unless (@cst = stat( $start ))
    {
	return undef;
    }

    unless (-d _) {
        # Make sure we can be invoked on plain files, not just directories.
        # NOTE that this routine assumes that '/' is the only directory separator.

        my ($dir, $file) = $start =~ m{^(.*)/(.+)$}
	    or return cwd() . '/' . $start;

	# Can't use "-l _" here, because the previous stat was a stat(), not an lstat().
	if (0 && -l $start) {
	    my $link_target = readlink($start);
	    die "Can't resolve link $start: $!" unless defined $link_target;

	    require File::Spec;
            $link_target = $dir . '/' . $link_target
                unless File::Spec->file_name_is_absolute($link_target);

	    return quick_abs_path($link_target);
	}

	return $dir ? quick_abs_path($dir) . "/$file" : "/$file";
    }

    $cwd = '';
    $dotdots = $start;
    do
    {
	$dotdots .= '/..';
	@pst = @cst;
	local *PARENT;
	unless (opendir(PARENT, $dotdots))
	{
	    return undef;
	}
	unless (@cst = stat($dotdots))
	{
	    my $e = $!;
	    closedir(PARENT);
	    $! = $e;
	    return undef;
	}
	if ($pst[0] == $cst[0] && $pst[1] == $cst[1])
	{
	    $dir = undef;
	}
	else
	{
	    do
	    {
		unless (defined ($dir = readdir(PARENT)))
	        {
		    closedir(PARENT);
		    require Errno;
		    $! = Errno::ENOENT();
		    return undef;
		}
		$tst[0] = $pst[0]+1 unless (@tst = lstat("$dotdots/$dir"))
	    }
	    while ($dir eq '.' || $dir eq '..' || $tst[0] != $pst[0] ||
		   $tst[1] != $pst[1]);
	}
	$cwd = (defined $dir ? "$dir" : "" ) . "/$cwd" ;
	closedir(PARENT);
    } while (defined $dir);
    chop($cwd) unless $cwd eq '/'; # drop the trailing /
    $cwd;
}

say quick_abs_path($ARGV[0]);

1;
#ABSTRACT: Print the resolved (absolute) path

=head1 DESCRIPTION

See the included script L<realpath> (or its alias (L<abspath>).


=head1 SEE ALSO

L<App::relpath>

L<App::quickabspath>
