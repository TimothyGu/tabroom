package Tab::JudgeGroup;
use base 'Tab::DBI';
Tab::JudgeGroup->table('judge_group');
Tab::JudgeGroup->columns(Primary => qw/id/);
Tab::JudgeGroup->columns(Essential => qw/name abbr/);
Tab::JudgeGroup->columns(Others => qw/judge_per missing_judge_fee uncovered_entry_fee 
										timestamp track_by_pools alt_max min_burden max_burden
										default_alt_reduce ask_paradigm strikes_explain conflicts
										paradigm_explain fee_missing tourn pub_assigns
										dio_min ask_alts free collective school_strikes
										strike_reg_opens strike_reg_closes max_pool_burden
										track_judge_hires hired_fee hired_pool cumulate_mjp
										special elim_special tab_room deadline live_updates
										ratings_need_paradigms ratings_need_entry
										strikes_need_paradigms strikes_need_entry 
										obligation_before_strikes coach_ratings school_ratings 
										entry_ratings entry_strikes /);

Tab::JudgeGroup->has_many(classes => "Tab::Class", "judge_group");
Tab::JudgeGroup->has_many(bins => "Tab::Bin", "judge_group");
Tab::JudgeGroup->has_many(quals => "Tab::Qual", "judge_group");
Tab::JudgeGroup->has_many(qual_subsets => "Tab::QualSubset", "judge_group");
Tab::JudgeGroup->has_many(pools => "Tab::Pool", "judge_group");
Tab::JudgeGroup->has_many(judges => "Tab::Judge", "judge_group");
Tab::JudgeGroup->has_many(hires => 'Tab::JudgeHire', 'judge_group');
Tab::JudgeGroup->has_a(default_alt_reduce => 'Tab::JudgeGroup');
Tab::JudgeGroup->has_a(tourn => "Tab::Tourn");

__PACKAGE__->_register_datetimes( qw/strike_reg_opens/);
__PACKAGE__->_register_datetimes( qw/strike_reg_closes/);
__PACKAGE__->_register_datetimes( qw/deadline/);

sub next_code { 
	
    my $self = shift;

	my %judges_by_code = ();
	foreach my $judge ($self->tourn->judges) { 
		$judges_by_code{$judge->code}++;
	}

    my $code = 100;

    while (defined $judges_by_code{$code}) { 
        $code++;
        $code++ if $code == 666;
        $code++ if $code == 69;
    }

    return $code;
}

sub hide_codes { 
	my $self = shift; 
	my $dont_hide;

	foreach my $event ($self->events) { 
		$dont_hide++ unless $event->no_codes;
	}

	return 1 unless $dont_hide;
	return;
}

sub all_school_ratings {
	my $self = shift;
	return Tab::Rating->search_school_ratings_by_group($self->id)
}

sub all_entry_ratings {
	my $self = shift;
	return Tab::Rating->search_entry_ratings_by_group($self->id)
}

sub count_judges {
    my $self = shift;
    return Tab::Judge->sql_count_by_group->select_val($self->id);
}

sub events {
	my $self = shift;
	return Tab::Event->search_by_group($self->id);
}

sub blockable { 
	my $self = shift;
	return Tab::Event->search_blockable_by_group($self->id);
}

sub struck {
	my $self = shift;
	return Tab::Judge->search_by_strikedness($self->id);
}

sub hired_number { 
	my $self = shift;
	Tab::JudgeGroup->set_sql(hired_count => "select sum(amount) 
											from judge_hire 
											where judge_group = ".$self->id);
	return Tab::JudgeGroup->sql_hired_count->select_val;
}

sub entries {
	my $self = shift;
	return Tab::Entry->search_by_group($self->id);
}

sub schools { 
	my $self = shift; 
	return Tab::School->search_by_group($self->id);
}

sub strikes { 
	my $self = shift;
	return Tab::Strike->search_by_group($self->id); 
}

sub setting {

	my ($self, $tag, $value, $text) = @_;

	my @existing = Tab::JudgeGroupSetting->search(  
		judge_group => $self->id,
		tag => $tag
	);

    if ($value &! $value == 0) {

		if (@existing) {

			my $exists = shift @existing;
			$exists->value($value);
			$exists->text($text);
			$exists->update;

			foreach my $other (@existing) { 
				$other->delete;
			}

			return;

		} else {

			Tab::JudgeGroupSetting->create({
				judge_group => $self->id,
				tag => $tag,
				value => $value,
				text => $text
			});

		}

	} else {

		return unless @existing;

		my $setting = shift @existing;

		foreach my $other (@existing) { 
			$other->delete;
		}

		return $setting->text if $setting->value eq "text";
		return $setting->value;

	}

}
