local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2) -- 융합 조건: 퍼니멀 + 에지임프

	-- ① 융합 소환 성공 시 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ② 엑스트라 덱 공개 → 덱에서 묘지 보내기
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.dump_tg)
	e2:SetOperation(s.dump_op)
	c:RegisterEffect(e2)

	-- ③ 상대 효과 무효 + 파괴 + 장착 + 공격력 증가
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

-- 융합 소재 필터
function s.matfilter1(c) return c:IsSetCard(0xa9) end -- 퍼니멀
function s.matfilter2(c) return c:IsSetCard(0xc3) end -- 에지임프

----------------------------------------
-- ① 융합 소환 성공 시 서치
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.thfilter(c)
	return (c:IsSetCard(0xa9) or c:IsSetCard(0xad)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

----------------------------------------
-- ② 엑스트라의 데스완구 융합 공개 → 덱 묘지
function s.dump_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.dump_filter_extra,tp,LOCATION_EXTRA,0,1,nil)
	end
end
function s.dump_filter_extra(c)
	return c:IsSetCard(0xad) and c:IsType(TYPE_FUSION) and c:IsMonster()
end

-- 덱에서 묘지로 보낼 수 있는 필터 (퍼니멀 또는 소재 명시된 몬스터)
function s.matfilter(c,matnames)
	return c:IsMonster() and c:IsAbleToGrave()
		and (c:IsSetCard(0xa9) or matnames[c:GetCode()])
end

function s.dump_op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.dump_filter_extra,tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	Duel.ConfirmCards(1-tp,tc)

	-- 융합 소재 이름 확인 (material 테이블 필요)
	local matnames = {}
	local matlist = tc.material
	if matlist then
		for _,code in ipairs(matlist) do
			matnames[code] = true
		end
	end

	-- 덱에서 묘지로 보내기
  local mg=Duel.SelectMatchingCard(tp,
	function(c) return s.matfilter(c,matnames) end,
	tp,LOCATION_DECK,0,1,2,nil)
	if #mg>0 then
		Duel.SendtoGrave(mg,REASON_EFFECT)
	end
end

----------------------------------------
-- ③ 효과 무효 + 파괴 + 장착 + 공격력 증가
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainDisablable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) and Duel.Destroy(rc,REASON_EFFECT)>0 then
		if rc:IsType(TYPE_MONSTER) and e:GetHandler():IsRelateToEffect(e) then
			Duel.Equip(tp,rc,e:GetHandler())
			-- 공격력 증가
			local atk=rc:GetAttack()
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e:GetHandler():RegisterEffect(e1)
			-- 장착 제한
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_EQUIP_LIMIT)
			e2:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
			e2:SetValue(1)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e2)
		end
	end
end
