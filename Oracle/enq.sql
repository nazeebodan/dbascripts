enq: MS – contention Oracle等待
当物化视图刷新时，可能出现大量的enq:ms等待事件
 
 
The event is raised because the MV is recompiled.
The alter summary compile is fired because the MV is created with query rewrite enabled.
The select query on the base table will try rewriting with the MV. But since MV is being refreshed, its invalid
and therefore compile statement is fired.
This is what is causing the wait event to be raised.
Therefore this was considered to be working as designed.
However, there is a useful solution for this
If you recreate your MV log with the ‘COMMIT SCN’ option, then this event should be gone
or at least drastically reduced.
This is described at
http://docs.oracle.com/cd/E11882_01/server.112/e41084/statements_6003.htm#SQLRF01303

========================================================================================================================================================================================================
Enqueue Type        Description
enq: AD – allocate AU        Synchronizes accesses to a specific OSM (Oracle Software Manager) disk AU
enq: AD – deallocate AU        Synchronizes accesses to a specific OSM disk AU
enq: AF – task serialization        Serializes access to an advisor task
enq: AG – contention        Synchronizes generation use of a particular workspace
enq: AO – contention        Synchronizes access to objects and scalar variables
enq: AS – contention        Synchronizes new service activation
enq: AT – contention        Serializes alter tablespace operations
enq: AW – AW$ table lock        Allows global access synchronization to the AW$ table (analytical workplace tables used in OLAP option)
enq: AW – AW generation lock        Gives in-use generation state for a particular workspace
enq: AW – user access for AW        Synchronizes user accesses to a particular workspace
enq: AW – AW state lock        Row lock synchronization for the AW$ table
enq: BR – file shrink        Lock held to prevent file from decreasing in physical size during RMAN backup
enq: BR – proxy-copy        Lock held to allow cleanup from backup mode during an RMAN proxy-copy backup
enq: CF – contention        Synchronizes accesses to the controlfile
enq: CI – contention        Coordinates cross-instance function invocations
enq: CL – drop label        Synchronizes accesses to label cache when dropping a label
enq: CL – compare labels        Synchronizes accesses to label cache for label comparison
enq: CM – gate        Serializes access to instance enqueue
enq: CM – instance        Indicates OSM disk group is mounted
enq: CT – global space management        Lock held during change tracking space management operations that affect the entire change tracking file
enq: CT – state        Lock held while enabling or disabling change tracking to ensure that it is enabled or disabled by only one user at a time
enq: CT – state change gate 2        Lock held while enabling or disabling change tracking in RAC
enq: CT – reading        Lock held to ensure that change tracking data remains in existence until a reader is done with it
enq: CT – CTWR process start/stop        Lock held to ensure that only one CTWR (Change Tracking Writer, which tracks block changes and is initiated by the alter database enable block change tracking command) process is started in a single instance
enq: CT – state change gate 1        Lock held while enabling or disabling change tracking in RAC
enq: CT – change stream ownership        Lock held by one instance while change tracking is enabled to guarantee access to thread-specific resources
enq: CT – local space management        Lock held during change tracking space management operations that affect just the data for one thread
enq: CU – contention        Recovers cursors in case of death while compiling
enq: DB – contention        Synchronizes modification of database wide supplemental logging attributes
enq: DD – contention        Synchronizes local accesses to ASM (Automatic Storage Management) disk groups
enq: DF – contention        Enqueue held by foreground or DBWR when a datafile is brought online in RAC
enq: DG – contention        Synchronizes accesses to ASM disk groups
enq: DL – contention        Lock to prevent index DDL during direct load
enq: DM – contention        Enqueue held by foreground or DBWR to synchronize database mount/open with other operations
enq: DN – contention        Serializes group number generations
enq: DP – contention        Synchronizes access to LDAP parameters
enq: DR – contention        Serializes the active distributed recovery operation
enq: DS – contention        Prevents a database suspend during LMON reconfiguration
enq: DT – contention        Serializes changing the default temporary table space and user creation
enq: DV – contention        Synchronizes access to lower-version Diana (PL/SQL intermediate representation)
enq: DX – contention        Serializes tightly coupled distributed transaction branches
enq: FA – access file        Synchronizes accesses to open ASM files
enq: FB – contention        Ensures that only one process can format data blocks in auto segment space managed tablespaces
enq: FC – open an ACD thread        LGWR opens an ACD thread
enq: FC – recover an ACD thread        SMON recovers an ACD thread
enq: FD – Marker generation        Synchronization
enq: FD – Flashback coordinator        Synchronization
enq: FD – Tablespace flashback on/off        Synchronization
enq: FD – Flashback on/off        Synchronization
enq: FG – serialize ACD relocate        Only 1 process in the cluster may do ACD relocation in a disk group
enq: FG – LGWR redo generation enq race        Resolves race condition to acquire Disk Group Redo Generation Enqueue
enq: FG – FG redo generation enq race        Resolves race condition to acquire Disk Group Redo Generation Enqueue
enq: FL – Flashback database log        Synchronizes access to Flashback database log
enq: FL – Flashback db command        Synchronizes Flashback Database and deletion of flashback logs
enq: FM – contention        Synchronizes access to global file mapping state
enq: FR – contention        Begins recovery of disk group
enq: FS – contention        Synchronizes recovery and file operations or synchronizes dictionary check
enq: FT – allow LGWR writes        Allows LGWR to generate redo in this thread
enq: FT – disable LGWR writes        Prevents LGWR from generating redo in this thread
enq: FU – contention        Serializes the capture of the DB feature, usage, and high watermark statistics
enq: HD – contention        Serializes accesses to ASM SGA data structures
enq: HP – contention        Synchronizes accesses to queue pages
enq: HQ – contention        Synchronizes the creation of new queue IDs
enq: HV – contention        Lock used to broker the high watermark during parallel inserts
enq: HW – contention        Lock used to broker the high watermark during parallel inserts
enq: IA – contention        Information not available
enq: ID – contention        Lock held to prevent other processes from performing controlfile transaction while NID is running
enq: IL – contention        Synchronizes accesses to internal label data structures
enq: IM – contention for blr        Serializes block recovery for IMU txn
enq: IR – contention        Synchronizes instance recovery
enq: IR – contention2        Synchronizes parallel instance recovery and shutdown immediate
enq: IS – contention        Synchronizes instance state changes
enq: IT – contention        Synchronizes accesses to a temp object’s metadata
enq: JD – contention        Synchronizes dates between job queue coordinator and slave processes
enq: JI – contention        Lock held during materialized view operations (such as refresh, alter) to prevent concurrent operations on the same materialized view
enq: JQ – contention        Lock to prevent multiple instances from running a single job
enq: JS – contention        Synchronizes accesses to the job cache
enq: JS – coord post lock        Lock for coordinator posting
enq: JS – global wdw lock        Lock acquired when doing wdw ddl
enq: JS – job chain evaluate lock        Lock when job chain evaluated for steps to create
enq: JS – q mem clnup lck        Lock obtained when cleaning up q memory
enq: JS – slave enq get lock2        Gets run info locks before slv objget
enq: JS – slave enq get lock1        Slave locks exec pre to sess strt
enq: JS – running job cnt lock3        Lock to set running job count epost
enq: JS – running job cnt lock2        Lock to set running job count epre
enq: JS – running job cnt lock        Lock to get running job count
enq: JS – coord rcv lock        Lock when coord receives msg
enq: JS – queue lock        Lock on internal scheduler queue
enq: JS – job run lock – synchronize        Lock to prevent job from running elsewhere
enq: JS – job recov lock        Lock to recover jobs running on crashed RAC inst
enq: KK – context        Lock held by open redo thread, used by other instances to force a log switch
enq: KM – contention        Synchronizes various Resource Manager operations
enq: KP – contention        Synchronizes kupp process startup
enq: KT – contention        Synchronizes accesses to the current Resource Manager plan
enq: MD – contention        Lock held during materialized view log DDL statements
enq: MH – contention        Lock used for recovery when setting Mail Host for AQ e-mail notifications
enq: ML – contention        Lock used for recovery when setting Mail Port for AQ e-mail notifications
enq: MN – contention        Synchronizes updates to the LogMiner dictionary and prevents multiple instances from preparing the same LogMiner session
enq: MR – contention        Lock used to coordinate media recovery with other uses of datafiles
enq: MS – contention        Lock held during materialized view refresh to set up MV log
enq: MW – contention        Serializes the calibration of the manageability schedules with the Maintenance Window
enq: OC – contention        Synchronizes write accesses to the outline cache
enq: OL – contention        Synchronizes accesses to a particular outline name
enq: OQ – xsoqhiAlloc        Synchronizes access to olapi history allocation
enq: OQ – xsoqhiClose        Synchronizes access to olapi history closing
enq: OQ – xsoqhistrecb        Synchronizes access to olapi history globals
enq: OQ – xsoqhiFlush        Synchronizes access to olapi history flushing
enq: OQ – xsoq*histrecb        Synchronizes access to olapi history parameter CB
enq: PD – contention        Prevents others from updating the same property
enq: PE – contention        Synchronizes system parameter updates
enq: PF – contention        Synchronizes accesses to the password file
enq: PG – contention        Synchronizes global system parameter updates
enq: PH – contention        Lock used for recovery when setting proxy for AQ HTTP notifications
enq: PI – contention        Communicates remote Parallel Execution Server Process creation status
enq: PL – contention        Coordinates plug-in operation of transportable tablespaces
enq: PR – contention        Synchronizes process startup
enq: PS – contention        Parallel Execution Server Process reservation and synchronization
enq: PT – contention        Synchronizes access to ASM PST metadata
enq: PV – syncstart        Synchronizes slave start_shutdown
enq: PV – syncshut        Synchronizes instance shutdown_slvstart
enq: PW – prewarm status in dbw0        DBWR0 holds this enqueue indicating pre-warmed buffers present in cache
enq: PW – flush prewarm buffers        Direct Load needs to flush prewarmed buffers if DBWR0 holds this enqueue
enq: RB – contention        Serializes OSM rollback recovery operations
enq: RF – synch: per-SGA Broker metadata        Ensures r/w atomicity of DG configuration metadata per unique SGA
enq: RF – synchronization: critical ai        Synchronizes critical apply instance among primary instances
enq: RF – new AI        Synchronizes selection of the new apply instance
enq: RF – synchronization: chief        Anoints 1 instance’s DMON (Data Guard Broker Monitor) as chief to other instance’s DMONs
enq: RF – synchronization: HC master        Anoints 1 instance’s DMON as health check master
enq: RF – synchronization: aifo master        Synchronizes critical apply instance failure detection and failover operation
enq: RF – atomicity        Ensures atomicity of log transport setup
enq: RN – contention        Coordinates nab computations of online logs during recovery
enq: RO – contention        Coordinates flushing of multiple objects
enq: RO – fast object reuse        Coordinates fast object reuse
enq: RP – contention        Enqueue held when resilvering is needed or when data block is repaired from mirror
enq: RS – file delete        Lock held to prevent file from accessing during space reclamation
enq: RS – persist alert level        Lock held to make alert level persistent
enq: RS – write alert level        Lock held to write alert level
enq: RS – read alert level        Lock held to read alert level
enq: RS – prevent aging list update        Lock held to prevent aging list update
enq: RS – record reuse        Lock held to prevent file from accessing while reusing circular record
enq: RS – prevent file delete        Lock held to prevent deleting file to reclaim space
enq: RT – contention        Thread locks held by LGWR, DBW0, and RVWR (Recovery Writer, used in Flashback Database operations) to indicate mounted or open status
enq: SB – contention        Synchronizes logical standby metadata operations
enq: SF – contention        Lock held for recovery when setting sender for AQ e-mail notifications
enq: SH – contention        Enqueue always acquired in no-wait mode – should seldom see this contention
enq: SI – contention        Prevents multiple streams table instantiations
enq: SK – contention        Serialize shrink of a segment
enq: SQ – contention        Lock to ensure that only one process can replenish the sequence cache
enq: SR – contention        Coordinates replication / streams operations
enq: SS – contention        Ensures that sort segments created during parallel DML operations aren’t prematurely cleaned up
enq: ST – contention        Synchronizes space management activities in dictionary-managed tablespaces
enq: SU – contention        Serializes access to SaveUndo Segment
enq: SW – contention        Coordinates the ‘alter system suspend’ operation
enq: TA – contention        Serializes operations on undo segments and undo tablespaces
enq: TB – SQL Tuning Base Cache Update        Synchronizes writes to the SQL Tuning Base Existence Cache
enq: TB – SQL Tuning Base Cache Load        Synchronizes writes to the SQL Tuning Base Existence Cache
enq: TC – contention        Lock held to guarantee uniqueness of a tablespace checkpoint
enq: TC – contention2        Lock during setup of a unique tablespace checkpoint in null mode
enq: TD – KTF dump entries        KTF dumping time/scn mappings in SMON_SCN_TIME table
enq: TE – KTF broadcast        KTF broadcasting
enq: TF – contention        Serializes dropping of a temporary file
enq: TL – contention        Serializes threshold log table read and update
enq: TM – contention        Synchronizes accesses to an object
enq: TO – contention        Synchronizes DDL and DML operations on a temp object
enq: TQ – TM contention        TM access to the queue table
enq: TQ – DDL contention        DDL access to the queue table
enq: TQ – INI contention        TM access to the queue table
enq: TS – contention        Serializes accesses to temp segments
enq: TT – contention        Serializes DDL operations on tablespaces
enq: TW – contention        Lock held by one instance to wait for transactions on all instances to finish
enq: TX – contention        Lock held by a transaction to allow other transactions to wait for it
enq: TX – row lock contention        Lock held on a particular row by a transaction to prevent other transactions from modifying it
enq: TX – allocate ITL entry        Allocating an ITL entry in order to begin a transaction
enq: TX – index contention        Lock held on an index during a split to prevent other operations on it
enq: UL – contention        Lock held used by user applications
enq: US – contention        Lock held to perform DDL on the undo segment
enq: WA – contention        Lock used for recovery when setting watermark for memory usage in AQ notifications
enq: WF – contention        Enqueue used to serialize the flushing of snapshots
enq: WL – contention        Coordinates access to redo log files and archive logs
enq: WP – contention        Enqueue to handle concurrency between purging and baselines
enq: XH – contention        Lock used for recovery when setting No Proxy Domains for AQ HTTP notifications
enq: XR – quiesce database        Lock held during database quiesce
enq: XR – database force logging        Lock held during database force logging mode
enq: XY – contention        Lock used by Oracle Corporation for internal testing
