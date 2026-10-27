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

#include "QuestPackets.h"

WorldPacket const* WorldPackets::Quest::QuestGiverStatusMultiple::Write()
{
    _worldPacket.WriteBits(QuestGiver.size(), 21);

    for (QuestGiverInfo const& questGiver : QuestGiver)
    {
        ObjectGuid guid = questGiver.Guid;

        _worldPacket.WriteBit(guid[4]);
        _worldPacket.WriteBit(guid[0]);
        _worldPacket.WriteBit(guid[3]);
        _worldPacket.WriteBit(guid[6]);
        _worldPacket.WriteBit(guid[5]);
        _worldPacket.WriteBit(guid[7]);
        _worldPacket.WriteBit(guid[1]);
        _worldPacket.WriteBit(guid[2]);
    }

    for (QuestGiverInfo const& questGiver : QuestGiver)
    {
        ObjectGuid guid = questGiver.Guid;

        _worldPacket.WriteByteSeq(guid[6]);
        _worldPacket.WriteByteSeq(guid[2]);
        _worldPacket.WriteByteSeq(guid[7]);
        _worldPacket.WriteByteSeq(guid[5]);
        _worldPacket.WriteByteSeq(guid[4]);
        _worldPacket << uint32(questGiver.Status);
        _worldPacket.WriteByteSeq(guid[1]);
        _worldPacket.WriteByteSeq(guid[3]);
        _worldPacket.WriteByteSeq(guid[0]);
    }

    return &_worldPacket;
}

WorldPacket const* WorldPackets::Quest::QuestUpdateComplete::Write()
{
    _worldPacket << uint32(QuestID);

    return &_worldPacket;
}