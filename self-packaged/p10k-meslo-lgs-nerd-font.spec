Name:      p10k-meslo-lgs-nerd-font
Version:   2.3.3
%global    picked_commit 145eb9fbc2f42ee408dacd9b22d8e6e0e553f83d
Release:   1%{?dist}
Summary:   The intended font for use with Tide, "The ultimate Fish prompt"

License:   Apache-2.0
URL:       https://github.com/romkatv/powerlevel10k-media

BuildArch: noarch

%global    fname_escaped() MesloLGS%%20NF%%20%1.ttf
%global    fname()         MesloLGS-NF-%1.ttf
%define    file_url()      %URL/blob/%picked_commit/%{fname_escaped %1}
Source0: %file_url Regular
Source1: %file_url Bold
Source2: %file_url Italic
Source3: %file_url Bold%20Italic

%description
# Description copied from the Tide readme
A gorgeous monospace font designed by Jim Lyles for Bitstream, customized for Apple, enhanced by André Berg, and 
finally patched by Roman Perepelitsa of Powerlevel10k with scripts originally developed by Ryan McIntyre of Nerd Fonts. 
Contains all the glyphs and symbols that Tide may need. Battle-tested in dozens of different terminals on all major 
operating systems.

Recommends:    fish
BuildRequires: coreutils

%setup -q

%build
%global install_dir %_datadir/fonts/p10k-meslo-lgs-nerd
%global build_dir   %buildroot%install_dir
%define install_cmd() install -Dm0644 %1 %build_dir/%{fname %2}
%install_cmd %SOURCE0 Regular
%install_cmd %SOURCE1 Bold
%install_cmd %SOURCE2 Italic
%install_cmd %SOURCE3 Bold-Italic

%files
%attr(0644,root,root) %install_dir/%{fname Regular}
%attr(0644,root,root) %install_dir/%{fname Bold}
%attr(0644,root,root) %install_dir/%{fname Italic}
%attr(0644,root,root) %install_dir/%{fname Bold-Italic}

%changelog
* Fri Jun 9 2023 Adam Beer <awebeer256@users.noreply.github.com> - 2.3.3-1
- Initial package
	