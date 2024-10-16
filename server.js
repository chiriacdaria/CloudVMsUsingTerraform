const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const app = express();
const port = 3000;

// Initialize VM counts
let linuxVmCount = 0;
let windowsVmCount = 0;

app.use(express.json());

// Serve the HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// API to create a virtual machine
app.post('/create-vm', (req, res) => {
    const osType = req.body.vm_os_type || 'Linux'; // Default to Linux
    let terraformCommand = '';
    console.log("VM: ", osType)
    if (osType === 'Linux') {
        linuxVmCount += 1;
        terraformCommand = `terraform apply -var 'linux_vm_count=${linuxVmCount}' -var 'windows_vm_count=${windowsVmCount}' -auto-approve -lock=false`;
    } else if (osType === 'Windows') {
        windowsVmCount += 1;
        terraformCommand = `terraform apply -var 'linux_vm_count=${linuxVmCount}' -var 'windows_vm_count=${windowsVmCount}' -auto-approve -lock=false`;
    }

    exec(terraformCommand, (error, stdout, stderr) => {
        if (error) {
            console.error(`Exec error: ${error}`);
            res.status(500).send('Error creating VM');
            return;
        }
        res.send(`VM (${osType}) created successfully`);
    });
});

// API to list VMs in the resource group
app.get('/list-vms', (req, res) => {
    const listCommand = `az vm list --resource-group my-vm-group --output json`;
    exec(listCommand, (error, stdout, stderr) => {
        if (error) {
            console.error(`Exec error: ${error}`);
            res.status(500).send('Error retrieving VM list');
            return;
        }
        const vmList = JSON.parse(stdout);
        res.json(vmList);
    });
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
