package acmesoft.procedures;

import org.voltdb.*;

/** A VoltDB stored procedure is a Java class defining one or
 * more SQL statements and implementing a <code>public
 * VoltTable[] run</code> method. VoltDB requires a
 * <code>ProcInfo</code> annotation providing metadata for the
 * procedure.  The <code>run</code> method is
 * defined to accept one or more parameters. These parameters take the
 * values the client passes via the
 * <code>Client.callProcedure</code> invocation.
 *
 * The <a href="https://community.voltdb.com/documentation">VoltDB
 * User Guide</a> specifies valid stored procedure definitions,
 * including valid run method parameter types, required annotation
 * metadata, and correct use the Volt query interface.
*/
@ProcInfo(
    partitionInfo = "NEPTUNE2.NEPTUNE2_ID: 0",
    singlePartition = true
)
public class Insert extends VoltProcedure {

    public final SQLStmt insertItem = new SQLStmt("INSERT INTO neptune2 VALUES (?, ?);");

    public long run( int NEPTUNE2_ID, long NEPTUNE2_ITEM ) throws VoltAbortException {
        // Add a SQL statement to the execution queue.
        voltQueueSQL( insertItem, NEPTUNE2_ID, NEPTUNE2_ITEM );

        // Run all queued queries.
        // Passing true parameter since this is the last voltExecuteSQL for this procedure.
        VoltTable[] retval = voltExecuteSQL(true);

        // Ensure there is one table as expected
        assert(retval.length == 1);
        // Use a convenience method to get one
        long modifiedTuples = retval[0].asScalarLong();
        // Check that one tuple was modified
        assert(modifiedTuples == 1);

        // This will be converted into an array of VoltTable for the client.
        // It will contain one table, with one column and one row.
        return modifiedTuples;
    }
}
