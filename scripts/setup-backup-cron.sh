#!/bin/bash

# Create backup directory if it doesn't exist
mkdir -p /home/vk-eveth/eveth-labs-platform/backups

# Create a daily backup script
cat > /home/vk-eveth/eveth-labs-platform/scripts/backup/run-daily-backup.sh << 'EOL'
#!/bin/bash

# Load environment variables
source /home/vk-eveth/eveth-labs-platform/.env

# Run the backup script
/home/vk-eveth/eveth-labs-platform/scripts/backup/backup.sh

# Log the backup completion
echo "$(date) - Backup completed" >> /home/vk-eveth/eveth-labs-platform/logs/backup.log
EOL

# Make the backup script executable
chmod +x /home/vk-eveth/eveth-labs-platform/scripts/backup/run-daily-backup.sh

# Add cron job to run backup daily at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /home/vk-eveth/eveth-labs-platform/scripts/backup/run-daily-backup.sh") | crontab -

echo "✅ Backup automation setup complete!"
echo "- Daily backups will run at 2 AM"
echo "- Backups will be stored in: /home/vk-eveth/eveth-labs-platform/backups/"
echo "- Logs are available at: /home/vk-eveth/eveth-labs-platform/logs/backup.log"
