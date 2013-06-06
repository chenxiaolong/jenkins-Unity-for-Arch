This is the Jenkins configuration for the Unity-for-Arch project (public instance here: [ipv4] cxl.epac.to:8091 or [ipv6] [2001:470:8:c14:216:3eff:fe54:ee1e]:8090). This is just a dump of all the configuration files I use. Everything is highly specific to my setup. I tried not to hard-code too much though (in regards to paths, etc). The scripts to require that Jenkins is running as the "jenkins" user.

To set up an identical Jenkins instance, just copy everything in Jenkins/ to the home directory of the Jenkins user. Everything in Scripts/ goes in /srv/jenkins/. Jenkins.sudo goes in /etc/sudoers.d/. Also, build-in-chroot.sh from the main Unity-for-Arch git repo must be copied to /srv/jenkins/.

I have the following plugins installed (which may or may not be required):

* AnsiColor
* Ant Plugin
* Any Build Step Plugin
* Build Blocker Plugin (my fork at https://github.com/chenxiaolong/build-blocker-plugin)
* conditional-buildstep
* Copy Artifact Plugin
* Credentials Plugin
* Dashboard View
* export dynamic job data
* External Monitor Job Type Plugin
* Fail The Build Plugin
* Flexible Publish Plugin
* Javadoc Plugin
* Jenkins Bazaar plugin
* Jenkins Clone Workspace SCM Plug-in
* Jenkins CVS Plug-in
* Jenkins GIT client plugin
* Jenkins GIT plugin
* Jenkins Mailer Plugin
* Jenkins Parameterized Trigger plugin
* Jenkins SSH Slaves plugin
* Jenkins Subversion Plug-in
* Jenkins Translation Assistance plugin
* Jenkins Workspace Cleanup Plugin
* LDAP Plugin
* Maven Integration plugin
* PAM Authentication plugin
* Priority Sorter
* Run Condition Plugin
* Sectioned View Plugin
* ThinBackup
* Token Macro Plugin
