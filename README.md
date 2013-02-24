This is the Jenkins configuration for the Unity-for-Arch project (public instance here: [ipv4] cxl.epac.to:8091 or [ipv6] [2001:470:8:c14:216:3eff:fe54:ee1e]:8090). This is just a dump of all the configuration files I use. Everything is highly specific to my setup. I tried not to hard-code too much though (in regards to paths, etc). The scripts to require that Jenkins is running as the "jenkins" user.

To set up an identical Jenkins instance, just copy everything in Jenkins/ to the home directory of the Jenkins user. Everything in Scripts/ goes in /srv/jenkins/. Jenkins.sudo goes in /etc/sudoers.d/. Also, build-in-chroot.sh from the main Unity-for-Arch git repo must be copied to /srv/jenkins/.

I have the following plugins installed (which may or may not be required):

* Jenkins Mailer Plugin
* External Monitor Job Type Plugin
* LDAP Plugin
* pam-auth
* Ant Plugin
* Javadoc Plugin
* Token Macro Plugin
* Maven Integration plugin
* Build Blocker Plugin (my fork at https://github.com/chenxiaolong/build-blocker-plugin)
* Run Condition Plugin
* conditional-buildstep
* Flexible Publish Plugin
* Any Build Step Plugin
* export dynamic job data
* Jenkins Subversion Plug-in
* Jenkins SSH Slaves plugin
* Dashboard View
* Jenkins Clone Workspace SCM Plug-in
* Priority Sorter
* Jenkins GIT client plugin
* Jenkins Parameterized Trigger plugin
* Jenkins GIT plugin
* Jenkins Translation Assistance plugin
* Sectioned View Plugin
* AnsiColor
* SCM Sync Configuration Plugin
* Fail the Build Plugin
* ThinBackup
* Jenkins CVS Plug-in
