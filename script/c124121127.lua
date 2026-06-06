-- 환홍마신 줄투르크
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 룰 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.hspcon)
	e1:SetTarget(s.hsptg)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)

	-- ②: 효과 처리 시 개입
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.effcon)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

-- ①번 효과 로직
function s.spfilter(c)
	return c:IsType(TYPE_SPELL|TYPE_TRAP) and c:IsAbleToRemoveAsCost() 
		and (c:IsLocation(LOCATION_HAND) or aux.SpElimFilter(c,true,true))
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,nil)
	return aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),0)
end

function s.hsptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND|LOCATION_GRAVE,0,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_REMOVE,nil,nil,true)
	if #g<1 then return false end
	g:KeepAlive()
	e:SetLabelObject(g)
	return true
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	g:DeleteGroup()
end

-- ②번 효과 발동 조건 (암흑계의 용신왕 그라파 공식 검증 메커니즘 완전 이식)
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	-- 발동한 카드 본체가 일반 마법이거나 일반 함정이며, 동시에 그것이 '카드의 발동'일 때만 참을 반환합니다.
	return rc and (rc:IsNormalSpell() or rc:IsNormalTrap()) and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end

-- 묘지로 보낼 카드 필터
function s.tgfilter(c)
	return c:IsAbleToGrave()
end

-- ②번 효과 처리
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	local b1 = Duel.GetFlagEffect(tp,id)==0 
	local b2 = Duel.GetFlagEffect(tp,id+1)==0 
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil)
	local b3 = Duel.GetFlagEffect(tp,id+2)==0 
	if b3 then
		local deck_count = Duel.GetFieldGroupCount(rp,LOCATION_DECK,0)
		if deck_count < 3 then b3 = false end
	end
	
	if not (b1 or b2 or b3) then return end

	if not Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then return end
	
	Duel.Hint(HINT_CARD,0,id)
	
	local ops={}
	local opval={}
	local off=1
	
	if b1 then
		ops[off]=aux.Stringid(id,1)
		opval[off]=1
		off=off+1
	end
	if b2 then
		ops[off]=aux.Stringid(id,2)
		opval[off]=2
		off=off+1
	end
	if b3 then
		ops[off]=aux.Stringid(id,3)
		opval[off]=3
		off=off+1
	end
	
	local op=Duel.SelectOption(tp,table.unpack(ops))
	local sel=opval[op+1]
	
	if sel==1 then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		if c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(800)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
		
	elseif sel==2 then
		Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
		if #g>0 then
			Duel.SendtoGrave(g,REASON_EFFECT)
		end
		
	elseif sel==3 then
		Duel.RegisterFlagEffect(tp,id+2,RESET_PHASE+PHASE_END,0,1)
		Duel.ChangeChainOperation(ev,s.repop)
	end
end

-- 변경된 효과 처리
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
	if #g>0 then
		Duel.DisableShuffleCheck()
		local sg=g:Filter(Card.IsType,nil,TYPE_TRAP):Filter(Card.IsSSetable,nil)
		local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
		
		if ft>0 and #sg>0 then
			if #sg>ft then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				sg=sg:Select(tp,ft,ft,nil)
			end
			Duel.SSet(tp,sg)
		end
		
		local rg=g:Filter(function(c) return not c:IsLocation(LOCATION_SZONE) end,nil)
		if #rg>0 then
			Duel.SendtoDeck(rg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_REVEAL)
		end
	end
end