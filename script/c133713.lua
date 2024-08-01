--Anguish of the Tenyi
local TENYI_SETNAME = 0x12c
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon procedure: 2 monsters, including a "Tenyi" monster
    c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,2,s.link_check)

	--This card is treated as a non-Effect Monster while face-up on the field.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_REMOVE_TYPE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(TYPE_EFFECT)
	--e1:SetCondition(s.eqcon1)
	c:RegisterEffect(e1)

	

end
--s.listed_series={TENYI_SETNAME}

function s.link_check(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,TENYI_SETNAME,lc,sumtype,tp)
end
