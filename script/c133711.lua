--Tenyi Codec
local TENYI_SETNAME = 0x12c
local s,id=GetID()
function s.initial_effect(c)
	--Activating the spell card (does nothing)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	--Search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CUSTOM+id)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTarget(s.search_tg)
	e2:SetOperation(s.search_op)
	c:RegisterEffect(e2)
	local g=Group.CreateGroup()
	g:KeepAlive()
	e2:SetLabelObject(g)

	--Mass register
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetLabelObject(e2)
	e3:SetOperation(s.register_op)
	c:RegisterEffect(e3)
	--Register attributes
	aux.GlobalCheck(s,function()
		s.attr_list={} -- We will use attr_list to track the attributes that have already been added to hand.
		s.attr_list[0]=0
		s.attr_list[1]=0
		aux.AddValuesReset(function()
				s.attr_list[0]=0
				s.attr_list[1]=0
			end)
		end)
end
s.listed_series={TENYI_SETNAME}

function s.search_trigger_filter(c,e,tp,re,rp) -- The filter for which cards trigger the search effect
	--local attr=c:GetAttribute()
	return c:IsSetCard(TENYI_SETNAME) and c:GetOwner()==tp and c:IsMonster()
		and c:IsLocation(LOCATION_REMOVED) and c:IsPreviousLocation(LOCATION_HAND+LOCATION_GRAVE)
		--and c:IsReason(REASON_COST) and re and re:IsActivated() and re:GetHandler():IsSetCard(TENYI_SETNAME)
		and rp==tp and c:IsCanBeEffectTarget(e)
		and Duel.IsExistingMatchingCard(s.search_filter,tp,LOCATION_DECK,0,1,nil,tp,c:GetAttribute())
end

function s.search_filter(c,tp,attr) -- The filter for which cards can be added to hand
	return c:IsSetCard(TENYI_SETNAME) and c:IsMonster() and not c:IsAttribute(attr) and s.attr_list[tp]&c:GetAttribute()==0 and c:IsAbleToHand()
end

function s.register_op(e,tp,eg,ep,ev,re,r,rp) -- Event handler for banish events
	local tg=eg:Filter(s.search_trigger_filter,nil,e,tp,re,rp)
	if #tg>0 then
		for tc in aux.Next(tg) do
			tc:RegisterFlagEffect(id,RESET_CHAIN,0,1)
		end
		local g=e:GetLabelObject():GetLabelObject()
		if Duel.GetCurrentChain()==0 then g:Clear() end
		g:Merge(tg)
		g:Remove(function(c) return c:GetFlagEffect(id)==0 end,nil)
		e:GetLabelObject():SetLabelObject(g)
		Duel.RaiseSingleEvent(e:GetHandler(),EVENT_CUSTOM+id,e,0,tp,tp,0)
	end
end

function s.search_tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=e:GetLabelObject():Filter(s.search_trigger_filter,nil,e,tp,re,rp)
	if chkc then return g:IsContains(chkc) and s.search_trigger_filter(chkc,e,tp,re,rp) end
	if chk==0 then return #g>0 and Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
	if #g==1 then
		Duel.SetTargetCard(g:GetFirst())
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=g:Select(tp,1,1,nil)
		Duel.SetTargetCard(tc)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.search_op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	local att=tc:GetAttribute()
	if not c:IsRelateToEffect(e) then return end
	if tc and tc:IsRelateToEffect(e) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.search_filter,tp,LOCATION_DECK,0,1,1,nil,tp,att)
		if #g>0 then
			local searched_card = g:GetFirst()
			Duel.SendtoHand(searched_card,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,searched_card)
			s.attr_list[tp]=s.attr_list[tp]|searched_card:GetAttribute() -- Update the attribute list
		end
		for _,str in aux.GetAttributeStrings(att) do
			c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,0,str)
		end
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,2),nil)
	--lizard check
	aux.addTempLizardCheck(e:GetHandler(),tp,s.lizfilter)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsRace(RACE_WYRM) and c:IsLocation(LOCATION_EXTRA)
end

function s.lizfilter(e,c)
	return not c:IsOriginalRace(RACE_WYRM)
end