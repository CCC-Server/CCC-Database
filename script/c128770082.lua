-- Fortune Lady Arki
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 스탠바이 페이즈에 레벨 상승
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return tp==Duel.GetTurnPlayer() end)
	e1:SetOperation(s.lvop)
	c:RegisterEffect(e1)

	-- ②: ATK / DEF 설정
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_BASE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkdefval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e3)

	-- ③: 소환 성공 시 효과 (1턴에 1번)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e5)

	-- ④: 포츈 레이디 카드 효과로 필드를 벗어났을 경우 (1턴에 1번)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCountLimit(1,{id,1})
	e6:SetCondition(s.leavecon)
	e6:SetOperation(s.leaveop)
	c:RegisterEffect(e6)
end

-- ①: 레벨 업
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and c:GetLevel()<12 then
		local lv=c:GetLevel()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end

-- ②: ATK/DEF 값 계산
function s.atkdefval(e,c)
	return c:GetLevel()*300
end

-- ③: 소환 성공 시 효과
function s.filter1(c)
	return c:IsSetCard(0x31) and c:IsMonster() and c:IsAbleToGrave()
end
function s.filter2(c,e,tp)
	return c:IsSetCard(0x31) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tg=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK,0,1,1,nil)
	if #tg>0 and Duel.SendtoGrave(tg,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		if #sg>0 and Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)>0 then
			-- 그 후 필드 위 포츈 레이디 1장 제외 가능
			if Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x31) and c:IsAbleToRemove() end,tp,LOCATION_MZONE,0,1,nil)
				and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
				local rg=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x31) and c:IsAbleToRemove() end,tp,LOCATION_MZONE,0,1,1,nil)
				if #rg>0 then
					Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
				end
			end
		end
	end
end

-- ④: 필드 이탈 조건
-- ④: 포츈 레이디 카드 효과로 필드를 벗어났을 경우
function s.leavecon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:IsActivated() and re:GetHandler():IsSetCard(0x31)
end

function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	local fg=g:Filter(function(c,e,tp)
		return c:IsSetCard(0x31) and c:IsMonster()
			and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
	end,nil,e,tp)
	if #fg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3)) -- "패에 넣거나 특수 소환할 카드를 고르세요"
		local sg=fg:Select(tp,1,1,nil)
		local sc=sg:GetFirst()
		if sc then
			if sc:IsCanBeSpecialSummoned(e,0,tp,false,false)
				and (not sc:IsAbleToHand() or Duel.SelectYesNo(tp,aux.Stringid(id,4))) then
				Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
			else
				Duel.SendtoHand(sc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sc)
			end
		end
	end
	Duel.ShuffleDeck(tp)
end

