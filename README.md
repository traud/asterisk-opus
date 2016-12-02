# Opus Codec for Asterisk

Opus is the default audio codec in WebRTC. WebRTC is available in Asterisk via SIP over WebSockets (WSS). Nevertheless, Opus can be used for other transports (UDP, TCP, TLS) as well. Opus supersedes previous codecs like CELT and SiLK. Furthermore in favor of Opus, other open-source audio codecs are no longer developed, like Speex, iSAC, iLBC, and Siren. If you use your Asterisk as a back-to-back user agent (B2BUA) and you transcode between various audio codecs, one should enable Opus for future compatibility.

Since Asterisk 13.12 (and Asterisk 14.0.1), Opus is not only supported for pass-through but can be transcoded as well. This allows you to translate to/from other audio codecs like those for landline telephones (ISDN: G.711; DECT: G.726-32; and HD: G.722) or mobile phones (GSM, AMR, AMR-WB, 3GPP EVS). This can be achieved by

A. enabling `codec_opus` via `make menuselect`, or

B. downloading the module from [Digium Downloads](http://www.digium.com/products/asterisk/downloads) » Add-on Voice Codecs, or

C. downloading the module [directly](http://downloads.digium.com/pub/telephony/codec_opus/).

That way, you get a binary module, which is closed software. Here, this repository offers Open Source Software. In contrast to a binary module, Open Source Software allows you to double-check the existing code, contribute and/or add your own features.

This repository is for Asterisk 13 and newer. If you still use Asterisk 11, please, [continue there…](https://github.com/meetecho/asterisk-opus) however, that variant does not offer negotiation of SDP parameters (fmtp). If you need that, please, upgrade to Asterisk 13.7 or newer.

## Installing
At least Asterisk 13.7 is required. These changes were last tested with Asterisk 13.13.0 (and Asterisk 14.1). If you use a newer version and transcoding fails, please, [report](https://help.github.com/articles/creating-an-issue/)!

	cd /usr/src/
	wget downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz
	tar zxf ./asterisk*
	cd ./asterisk*
	sudo apt-get --assume-yes install build-essential autoconf libssl-dev libncurses-dev libnewt-dev libxml2-dev libsqlite3-dev uuid-dev libjansson-dev libblocksruntime-dev xmlstarlet

Install libraries:

To support transcoding, you’ll need to install an Opus library, for example in Debian/Ubuntu:

	sudo apt-get --assume-yes install libopusfile-dev

Apply all changes:

	wget github.com/traud/asterisk-opus/archive/asterisk-13.7.tar.gz
	tar zxf ./master.tar.gz
	rm ./master.tar.gz
	cp --verbose ./asterisk-opus*/include/asterisk/* ./include/asterisk
	cp --verbose ./asterisk-opus*/codecs/* ./codecs
	cp --verbose ./asterisk-opus*/res/* ./res

(Optionally) apply the patch for File Formats (untested):

Two format modules are added which allow you to play VP8 and Ogg Opus files without transcoding.

	cp --verbose ./asterisk-opus*/formats/* ./formats
	patch -p1 <./asterisk-opus*/asterisk.patch

(Optionally) apply the patch for Native PLC (experimental):

Out of the box, Asterisk does not detect lost (or late) RTP packets. Such a detection is required to conceal lost packets (PLC). PLC improves situations like Wi-Fi Roaming or mobile-phone handovers. This patch detects lost/late packets but is experimental. If your scenario requires PLC and you find an issue with this patch, please, continue with [ASTERISK-25629…](http://issues.asterisk.org/jira/browse/ASTERISK-25629)

	patch -p1 <./asterisk-opus*/enable_native_plc.patch

Run the bootstrap script to re-generate configure:

	./bootstrap.sh

Configure your patched Asterisk:

	./configure

Enable slin16 in menuselect for transcoding, for example via:

	make menuselect.makeopts
	./menuselect/menuselect --enable-category MENUSELECT_CORE_SOUNDS

Compile and install:

	make
	sudo make install

Alternatively, you can use the Makefile of this repository to create just the shared libraries of the modules. That way, you do not have to (re-) make your whole Asterisk. 

## Testing
Opus is the default audio codec in WebRTC. Therefore, you can use Mozilla Firefox or Google Chrome via SIP over WebSockets in Asterisk. However, many traditional apps (SIP over UDP) added Opus as well. Simply add `allow=opus` in your configuration file `sip.conf` and the SIP channel driver `chan_sip` is able to negotiate Opus via SDP.

However, when you use a traditional VoIP app, please, double-check with your app vendor, whether [RFC 7587](http://tools.ietf.org/html/rfc7587) is known and supported. Many Opus enabled apps still use outdated SDP parameters (fmtp) and have not updated to the latest version of this RFC from June 2015. Furthermore, there are still apps which do not handle a `rtpmap` with `/2` at the end, because those apps do not know that Opus advertises two channels in SDP always. Some apps do not increment the RTP timestamps correctly. Finally, I am aware of just a few apps which allow you to tailor Opus for your bandwidth needs. Or stated differently: Many apps use fullband all the time. This increases the bitrate unnecessarily, if the attached microphone, earpiece, or loudspeaker do not support that frequency range. Tests revealed that Asterisk might not even force a lower bandwidth because many apps do not honor the send SDP parameters. Consequently with such an app, users tend to go for older audio codecs because they experience no benefit.

The app [Acrobits Softphone](http://itunes.apple.com/app/id314192799?mt=8) for Apple iOS lets you tailor the bandwidth and therefore recommended for your initial tests. Because the current app situation is like that, do not forget to allow legacy audio codecs even [SiLK 12 kHz](https://github.com/traud/asterisk-silk) and [iLBC 20](https://github.com/traud/asterisk-silk). If you are interested not in music but just in voice, you might even consider to prefer older wideband audio-codecs like G.722 (landline telephones) and [AMR-WB](https://github.com/traud/asterisk-amr) (mobile-operator gateway).

## What is missing
* `codecs.conf`: Instead, you have to change the file `include/asterisk/opus.h` and re-make Asterisk. The binary module from Digium supports the configuration file `codecs.conf`.
* Forward Error Correction (FEC) based on the actual packet loss reported by the remote party via RTCP, called Adaptive FEC. FreeSWITCH offers Opus with FEC.
* Packetization Time `ptime` of the channel driver is unknown to the Opus encoder. Therefore, Asterisk is going to create 20 ms despite the negotiated amount of frames. A high ptime is useful only for low bitrates.

This transcoding module works for me and contains everything I need. If you cannot code yourself, however, you need one of these or even another feature, please, [report](https://help.github.com/articles/creating-an-issue/).


## Thanks go to
* [Opus team](http://www.opus-codec.org/contact/),
* Ron Lee packaging the libraries for Debian/Ubuntu,
* [Lorenzo Miniero](https://github.com/meetecho/asterisk-opus) created the original code for Asterisk 11,
* [Tzafrir Cohen](http://issues.asterisk.org/jira/browse/ASTERISK-21981) drove the pass-through support for Asterisk 13,
* [Sean Bright](https://github.com/seanbright/asterisk-opus) ported the transcoding code over to Asterisk 13, added many changes directly into Asterisk 13, and maintained the port until Asterisk 13.11.
