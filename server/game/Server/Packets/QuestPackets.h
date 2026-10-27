/*
* This file is part of the Legends of Azeroth Pandaria Project. See THANKS file for Copyright information
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or (at your
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
* more details.
*
* You should have received a copy of the GNU General Public License along
* with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef QuestPackets_h__
#define QuestPackets_h__

#include "ObjectGuid.h"
#include "Packet.h"
#include "QuestDef.h"

namespace WorldPackets
{
    namespace Quest
    {
        // Empty packet, server replies with quest giver status of visible creatures
        class QuestGiverStatusMultipleQuery final : public ClientPacket
        {
        public:
            QuestGiverStatusMultipleQuery(WorldPacket&& packet) : ClientPacket(CMSG_QUESTGIVER_STATUS_MULTIPLE_QUERY, std::move(packet)) { }

            void Read() override { }
        };

        struct QuestGiverInfo
        {
            QuestGiverInfo() { }
            QuestGiverInfo(ObjectGuid const& guid, QuestGiverStatus status)
                : Guid(guid), Status(status) { }

            ObjectGuid Guid;
            QuestGiverStatus Status = QuestGiverStatus::None;
        };

        class QuestUpdateComplete final : public ServerPacket
        {
        public:
            QuestUpdateComplete() : ServerPacket(SMSG_QUEST_UPDATE_COMPLETE, 4) { }

            WorldPacket const* Write() override;

            int32 QuestID = 0;
        };

        class QuestGiverStatusMultiple final : public ServerPacket
        {
        public:
            QuestGiverStatusMultiple() : ServerPacket(SMSG_QUESTGIVER_STATUS_MULTIPLE, 24) { }

            WorldPacket const* Write() override;

            std::vector<QuestGiverInfo> QuestGiver;
        };
    }
}

#endif