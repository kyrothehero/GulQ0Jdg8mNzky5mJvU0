--Anguish of the Tenyi
local TENYI_SETNAME = 0x12c
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon procedure: 2 Wyrm monsters
    c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_WYRM),2,2)

	--This card is treated as a non-Effect Monster while face-up on the field.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_REMOVE_TYPE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(TYPE_EFFECT)
	--e1:SetCondition(s.eqcon1)
	c:RegisterEffect(e1)

	--You can target 1 face-up monster your opponent controls; 
	--immediately after this effect resolves, Link Summon 1 non-Effect Link Monster 
	--by using only that opponent's monster and this card you control as material.
	--You can only use this effect of "Anguish of the Tenyi" once per turn.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
--s.listed_series={TENYI_SETNAME}

function s.lkfilter(c,mg)
	return not c:IsType(TYPE_EFFECT) and c:IsLinkSummonable(nil,mg,2,2)
end
function s.filter(tc,c,tp)
	local mg=Group.FromCards(c,tc)
	return tc:IsFaceup() and tc:IsCanBeLinkMaterial() and Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.filter(chkc,e:GetHandler(),tp) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,0,LOCATION_MZONE,1,nil,e:GetHandler(),tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_MZONE,1,1,nil,e:GetHandler(),tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e)then
		local mg=Group.FromCards(c,tc)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.lkfilter,tp,LOCATION_EXTRA,0,1,1,nil,mg)
		local sc=g:GetFirst()
		if sc then
			Duel.LinkSummon(tp,sc,nil,mg,2,2)
		end
	end
end
