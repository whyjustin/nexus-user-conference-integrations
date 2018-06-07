def nxiqConfiguration = [new org.sonatype.nexus.ci.config.NxiqConfiguration('${nxiqUrl}', 'nxiq-credential-id')]
org.sonatype.nexus.ci.config.GlobalNexusConfiguration.globalNexusConfiguration.iqConfigs = nxiqConfiguration
